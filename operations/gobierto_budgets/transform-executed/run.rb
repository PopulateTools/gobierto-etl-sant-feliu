#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

require "json"

# Usage:
#
#  - Must be ran as an independent Ruby script
#
# Arguments:
#
#  - 0: Absolute path to a file containing a JSON downloaded from Sant Feliu data source
#  - 1: Absolute path of the output file
#  - 2: Year of the data
#  - 3: Kind of budget line (G or I)
#
# Samples:
#
#   /path/to/project/operations/gobierto_budgets/transform-executed/run.rb input.json output.json 2010 G
#

if ARGV.length != 4
  raise "At least one argument is required"
end

input_file = ARGV[0]
output_file = ARGV[1]
year = ARGV[2].to_i
kind = ARGV[3]

puts "[START] transform-executed/run.rb with file=#{input_file} output=#{output_file} year=#{year}"

json_data = JSON.parse(File.read(input_file))

place = INE::Places::Place.find_by_slug('sant-feliu-de-llobregat')
population = GobiertoData::GobiertoBudgets::Population.get(place.id, year)

base_data = {
  organization_id: place.id,
  ine_code: place.id.to_i,
  province_id: place.province.id.to_i,
  autonomy_id: place.province.autonomous_region.id.to_i,
  year: year,
  population: population
}


def normalize_data(data, kind)
  normalized_data = {}

  data.each do |row|
    next if row["fase_desc"] != "Pagat" && row["fase_desc"] != "Cobrat"

    amount = row["imp"].to_f

    if kind == GobiertoData::GobiertoBudgets::EXPENSE
      if row["prog"]
        # Level 3
        code = row["prog"][0..2]
        normalized_data[code] ||= 0
        normalized_data[code] += amount

        # Level 2
        code = row["prog"][0..1]
        normalized_data[code] ||= 0
        normalized_data[code] += amount

        # Level 1
        code = row["prog"][0]
        normalized_data[code] ||= 0
        normalized_data[code] += amount
      end
    elsif kind == GobiertoData::GobiertoBudgets::INCOME
      # For income data, there's no children information, just first level
      code = row["cap"]
      normalized_data[code] ||= 0
      normalized_data[code] += amount
    end
  end

  normalized_data
end

def normalize_data_economic_expenses(data, kind)
  normalized_data = {}

  data.each do |row|
    next if row["fase_desc"] != "Pagat" && row["fase_desc"] != "Cobrat"

    amount = row["imp"].to_f

    if kind == GobiertoData::GobiertoBudgets::EXPENSE
      code = row["cap"]
      normalized_data[code] ||= 0
      normalized_data[code] += amount
    end
  end

  normalized_data
end

def hydratate(options)
  area_name = options.fetch(:area_name)
  data      = options.fetch(:data)
  base_data = options.fetch(:base_data)
  kind      = options.fetch(:kind)

  data.map do |code, amount|
    code  = code.to_s
    level = code.length
    parent_code = level == 1 ? nil : code[0..-2]

    base_data.merge(amount: amount.round(2), code: code, level: level, kind: kind,
                    amount_per_inhabitant: base_data[:population] ? (amount / base_data[:population]).round(2) : nil,
                    parent_code: parent_code, type: area_name)
  end
end

normalized_data = normalize_data(json_data, kind)
if(kind == GobiertoData::GobiertoBudgets::INCOME)
  output_data = hydratate(data: normalized_data, area_name: GobiertoData::GobiertoBudgets::ECONOMIC_AREA_NAME, kind: kind, base_data: base_data)
else
  output_data = hydratate(data: normalized_data, area_name: GobiertoData::GobiertoBudgets::FUNCTIONAL_AREA_NAME, kind: kind, base_data: base_data)
  normalized_data = normalize_data_economic_expenses(json_data, kind)
  output_data += hydratate(data: normalized_data, area_name: GobiertoData::GobiertoBudgets::ECONOMIC_AREA_NAME, kind: kind, base_data: base_data)
end

File.write(output_file, output_data.to_json)

puts "[END] transform-executed/run.rb output=#{output_file}"

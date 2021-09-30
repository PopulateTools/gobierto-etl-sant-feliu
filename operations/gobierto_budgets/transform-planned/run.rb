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
#
# Samples:
#
#   /path/to/project/operations/gobierto_budgets/transform-planned/run.rb input.json output.json 2010
#

if ARGV.length != 3
  raise "At least one argument is required"
end

input_file = ARGV[0]
output_file = ARGV[1]
year = ARGV[2].to_i

puts "[START] transform-planned/run.rb with file=#{input_file} output=#{output_file} year=#{year}"

json_data = JSON.parse(File.read(input_file))

place = INE::Places::Place.find_by_slug('sant-feliu-de-llobregat')
population = GobiertoBudgetsData::GobiertoBudgets::Population.get(place.id, year)

base_data = {
  organization_id: place.id,
  ine_code: place.id.to_i,
  province_id: place.province.id.to_i,
  autonomy_id: place.province.autonomous_region.id.to_i,
  year: year,
  population: population
}

def normalize_data(data)
  income_data = {}
  expenses_functional_data = {}
  expenses_economic_data = {}

  data.each do |row|
    # income
    if row["codi"].length == 14
      income_data = process_row(row, income_data)
      # expense
    elsif row["codi"].length == 20
      expenses_functional_data = process_row(row, expenses_functional_data)
      expenses_economic_data = process_row(row, expenses_economic_data, true)
    else
      raise "Invalid row: #{row.inspect}"
    end
  end

  return income_data, expenses_functional_data, expenses_economic_data
end

def process_row(row, data, economic_expenses = false)
  amount = row["ini"].to_f
  full_code = row["codi"].split(' ')[1]

  # Level 3
  code = economic_expenses ? full_code[5..7] : full_code[0..2]
  data[code] ? data[code] += amount : data[code] = amount

  # Level 2
  code = economic_expenses ? full_code[5..6] : full_code[0..1]
  data[code] ? data[code] += amount : data[code] = amount

  # Level 1
  code = economic_expenses ? full_code[5] : full_code[0]
  data[code] ? data[code] += amount : data[code] = amount

  return data
end

def hydratate(options)
  area_name = options.fetch(:area_name)
  data      = options.fetch(:data)
  kind      = options.fetch(:kind)
  base_data = options.fetch(:base_data)

  data.map do |code, amount|
    code = code.to_s
    level = code.length
    parent_code = level == 1 ? nil : code[0..-2]

    base_data.merge(amount: amount.round(2), code: code, level: level, kind: kind,
                    amount_per_inhabitant: base_data[:population] ? (amount / base_data[:population]).round(2) : nil,
                    parent_code: parent_code, type: area_name)
  end
end

income_data, expenses_functional_data, expenses_economic_data = normalize_data(json_data)

output_data = hydratate(data: income_data, area_name: GobiertoBudgetsData::GobiertoBudgets::ECONOMIC_AREA_NAME, kind: GobiertoBudgetsData::GobiertoBudgets::INCOME, base_data: base_data) +
                hydratate(data: expenses_functional_data, area_name: GobiertoBudgetsData::GobiertoBudgets::FUNCTIONAL_AREA_NAME, kind: GobiertoBudgetsData::GobiertoBudgets::EXPENSE, base_data: base_data) +
                hydratate(data: expenses_economic_data, area_name: GobiertoBudgetsData::GobiertoBudgets::ECONOMIC_AREA_NAME, kind: GobiertoBudgetsData::GobiertoBudgets::EXPENSE, base_data: base_data)

File.write(output_file, output_data.to_json)

puts "[END] transform-planned/run.rb output=#{output_file}"

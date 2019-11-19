#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

require "json"

# This script imports Sant Feliu GCI indicators
#
# Usage:
#
#  - Must be ran as a Gobierto runner
#
# Arguments:
#
#  - 0: site domain
#
# Samples:
#
#   /path/to/gobierto/bin/rails runner /path/to/project/operations/gobierto_indicators/import_gci/run.rb domain.gobierto.test

domain     = ARGV[0]
@site      = Site.find_by domain: domain
WEBSERVICE_URL = "http://ajbpm.sfl.cat/JGenesysWS/services/IndicadorsWS?wsdl"

puts "[START] import_gci/run.rb with domain: #{domain}"

@gci = [
  {
    "id": 2,
    "level": 0,
    "attributes": {
      "title": "Q - Qualitat de Vida"
    },
    "children": [
      {
        "id": 1,
        "level": 1,
        "attributes": {
          "title": "Participació ciutadana"
        },
        "children": []
      },
      {
        "id": 4,
        "level": 1,
        "attributes": {
          "title": "Medi ambient"
        },
        "children": []
      },
      {
        "id": 6,
        "level": 1,
        "attributes": {
          "title": "Equitat Social"
        },
        "children": []
      },
      {
        "id": 7,
        "level": 1,
        "attributes": {
          "title": "Tecnologia i Innovació"
        },
        "children": []
      }
    ]
  },
  {
    "id": 1,
    "level": 0,
    "attributes": {
      "title": "S - Serveis de ciutat"
    },
    "children": [
      {
        "id": 1,
        "level": 1,
        "attributes": {
          "title": "Població"
        },
        "children": []
      },
      {
        "id": 10,
        "level": 1,
        "attributes": {
          "title": "Seguretat"
        },
        "children": []
      },
      {
        "id": 11,
        "level": 1,
        "attributes": {
          "title": "Residus sòlids"
        },
        "children": []
      },
      {
        "id": 12,
        "level": 1,
        "attributes": {
          "title": "Transport"
        },
        "children": []
      },
      {
        "id": 13,
        "level": 1,
        "attributes": {
          "title": "Aigües residuals"
        },
        "children": []
      },
      {
        "id": 14,
        "level": 1,
        "attributes": {
          "title": "Aigua"
        },
        "children": []
      },
      {
        "id": 16,
        "level": 1,
        "attributes": {
          "title": "Finances"
        },
        "children": []
      },
      {
        "id": 2,
        "level": 1,
        "attributes": {
          "title": "Habitatges"
        },
        "children": []
      },
      {
        "id": 3,
        "level": 1,
        "attributes": {
          "title": "Economia"
        },
        "children": []
      },
      {
        "id": 4,
        "level": 1,
        "attributes": {
          "title": "Govern"
        },
        "children": []
      },
      {
        "id": 5,
        "level": 1,
        "attributes": {
          "title": "Geografia i Clima"
        },
        "children": []
      },
      {
        "id": 6,
        "level": 1,
        "attributes": {
          "title": "Educació"
        },
        "children": []
      },
      {
        "id": 9,
        "level": 1,
        "attributes": {
          "title": "Recreació"
        },
        "children": []
      }
    ]
  }
]

client = Savon.client(wsdl: WEBSERVICE_URL)

response = client.call(:consulta_indicadors, message: { peticio: {indicadornom: 'GCI'}})
indicators = response.body.first.last.first.last.first.last

indicators.each do |indicator|
  indicator_splitted = indicator[:indicadornom].split(".")
  letter = if indicator_splitted[3].to_i == 1
             1
           else
             0
           end
  section_id = indicator_splitted[4].to_i

  title = indicator[:indicadornom].sub(/^GCI.[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\./, '')

  if ![8].include?(section_id) &&
    !(letter == 0 && section_id == 5) &&
    !title.include?("Consum total d'aigua per habitant") &&
    !title.include?("Consum domèstic d'aigua per habitant")

    section = @gci[letter][:children].index {|section| section[:id] == section_id }

    id = indicator_splitted[5].to_i

    values_response = client.call(:consulta_valors_indicador, message: { peticio: {indicadordef: indicator[:indicadordef] }})

    values = []

    values_response.body.first.last.first.last.first.last.each do |value|
      key = value[:dany].to_i
      value = value[:valor].gsub(".","").gsub(",",".")

      value += "%" if indicator[:indicadordesc].include?("percentatge") ||
                      indicator[:indicadordesc].include?("Percentatge")

      value += "€" if title.include?("Pressupost") || title.include?("pressupost")

      h = { key => value.strip }

      values.push(h)
    end

    values = values.sort_by { |k| k.keys[0] }

    @gci[letter][:children][section][:children].push({ id: id,
                                                       level: 2,
                                                       attributes: { title: title,
                                                                     source: indicator[:publfont],
                                                                     description: indicator[:indicadordesc],
                                                                     methodology: indicator[:publmetode],
                                                                     calculation: indicator[:publcalcul],
                                                                     values: values}})
  end
end

# Order arrays and update id
index = 1
@gci.each do |letter|
  letter[:children].each do |number|
    number[:children] = number[:children].sort_by { |hsh| hsh[:id] }

    number[:children].each do |indicator|
      indicator[:id] = index
      index += 1
    end
  end
end

GobiertoIndicators::IndicatorsImporter.new("gci", @site, @gci.to_json).import!

puts "[END] import_gci/run.rb with domain: #{domain}"


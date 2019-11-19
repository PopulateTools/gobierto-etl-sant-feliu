#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

require "json"

# This script imports Sant Feliu Infoparticipa 2018 indicators
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
#   /path/to/gobierto/bin/rails runner /path/to/project/operations/gobierto_indicators/import_ip18/run.rb domain.gobierto.test

domain     = ARGV[0]
@site      = Site.find_by domain: domain
@year      = 2018
WEBSERVICE_URL = "http://ajbpm.sfl.cat/JGenesysWS/services/IndicadorsWS?wsdl"

puts "[START] import_ip18/run.rb with domain: #{domain}"

@ip18 = [
  {
    "id": 0,
    "level": 0,
    "attributes": {
      "title": "I - infoparticipa"
    },
    "children": [
      {
        "id": 0,
        "level": 1,
        "attributes": {
          "title": "Qui són els representants polítics?"
        },
        "children": []
      },
      {
        "id": 1,
        "level": 1,
        "attributes": {
          "title": "Com gestionen els recursos col·lectius? "
        },
        "children": []
      },
      {
        "id": 2,
        "level": 1,
        "attributes": {
          "title": "Com informen de la gestió dels recursos col·lectius?"
        },
        "children": []
      },
      {
        "id": 3,
        "level": 1,
        "attributes": {
          "title": "Quines eines ofereixen per a la participació ciutadana en el control democràtic?"
        },
        "children": []
      },
      {
        "id": 4,
        "level": 1,
        "attributes": {
          "title": "Quines eines s'ofereixen per a la participació ciutadana?"
        },
        "children": []
      }
    ]
  }
]

client = Savon.client(wsdl: WEBSERVICE_URL)

response = client.call(:consulta_indicadors, message: { peticio: {indicadornom: 'IP18'}})

indicators = response.body.first.last.first.last.first.last

indicators.each do |indicator|
  indicator_splitted = indicator[:indicadornom].split(".")
  section = indicator_splitted[1].to_i - 1
  id = indicator_splitted[2].to_i
  title = indicator[:indicadordesc].split(/[0-9]+. /).last

  response = client.call(:consulta_valors_indicador, message: { peticio: {indicadordef: indicator[:indicadordef] }})
  value = !(response.body.first.last.first.last.first.last[:valor].nil?)

  links = []

  if value
    if response.body.first.last.first.last.first.last.key?(:valor)
      value_links = response.body.first.last.first.last.first.last[:valor]
      value_links = value_links.gsub("http//","http://").gsub("https//","https://")
      sentences = value_links.split(/: https?:\/\/[\S]+/)
      urls = value_links.scan(/https?:\/\/[\S]+/)

      unless urls.empty?
        sentences.each_index do |i|
          h = { link: { title: sentences[i].strip, url: urls[i] }}
          links.push(h)
        end
      end
    end
  end

  @ip18[0][:children][section][:children].push({ id: id, level: 2, attributes: { title: title, checked: value, links: links }})
end

# Order arrays

@ip18.each do |letter|
  letter[:children].each do |number|
    number[:children] = number[:children].sort_by { |hsh| hsh[:id] }
  end
end

puts "[DEBUG] Generating Indicators Infoparticipa 18..."

GobiertoIndicators::IndicatorsImporter.new("ip", @site, @ip18.to_json, @year).import!

puts "[END] import_ip18/run.rb"

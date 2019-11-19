#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

require "json"

# This script imports Sant Feliu Infoparticipa 2012 indicators
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
#   /path/to/gobierto/bin/rails runner /path/to/project/operations/gobierto_indicators/import_ip12/run.rb domain.gobierto.test

domain     = ARGV[0]
@site      = Site.find_by domain: domain
@year      = 2012
WEBSERVICE_URL = "http://ajbpm.sfl.cat/JGenesysWS/services/IndicadorsWS?wsdl"

puts "[START] import_ip12/run.rb with domain: #{domain}"

@ip12 = [
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
          "title": "Com gestionen els recursos col·lectius?"
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
      }
    ]
  }
]

client = Savon.client(wsdl: WEBSERVICE_URL)

response = client.call(:consulta_indicadors, message: { peticio: {indicadornom: 'IP12'}})
indicators = response.body.first.last.first.last.first.last

indicators.each do |indicator|
  indicator_splitted = indicator[:indicadordesc].split(". ")
  id = indicator_splitted.first.to_i

  title = indicator[:indicadordesc].split(/[0-9]+. /).last

  ip_section = if id <= 6
                 0
               elsif id > 6 && id <= 21
                 1
               elsif 21 > 6 && id <= 28
                 2
               else
                 3
               end

   response = client.call(:consulta_valors_indicador, message: { peticio: {indicadordef: indicator[:indicadordef] }})

   links = []

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

  @ip12[0][:children][ip_section][:children].push({ id: id, level: 2, attributes: { title: title, checked: true, links: links }})
end

# Order arrays

@ip12.each do |letter|
  letter[:children].each do |number|
    number[:children] = number[:children].sort_by { |hsh| hsh[:id] }
  end
end

puts "[DEBUG] Generating Indicators Infoparticipa 12..."

GobiertoIndicators::IndicatorsImporter.new("ip", @site, @ip12.to_json, @year).import!

puts "[END] import_ip12/run.rb"

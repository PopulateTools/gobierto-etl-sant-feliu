#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

require "json"

# This script imports Sant Feliu ITA 2014 indicators
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
#   /path/to/gobierto/bin/rails runner /path/to/project/operations/gobierto_indicators/import_ita14/run.rb domain.gobierto.test

domain     = ARGV[0]
@site      = Site.find_by domain: domain
@year      = 2014
WEBSERVICE_URL = "http://ajbpm.sfl.cat/JGenesysWS/services/IndicadorsWS?wsdl"

puts "[START] import_ita14/run.rb with domain: #{domain}"

@ita14 = [
  {
    "id": 0,
    "level": 0,
    "attributes": {
      "title": "A - Informació sobre la Corporació Municipal"
    },
    "children": [
      {
        "id": 0,
        "level": 1,
        "attributes": {
          "title": "A.1.- Informació sobre els càrrecs electes i el personal"
        },
        "children": []
      },
      {
        "id": 1,
        "level": 1,
        "attributes": {
          "title": "A.2 - Informació sobre l´organització i el patrimoni"
        },
        "children": []
      },
      {
        "id": 2,
        "level": 1,
        "attributes": {
          "title": "A.3 - Informació sobre normes i institucions municipals"
        },
        "children": []
      }
    ]
  },
  {
    "id": 1,
    "level": 0,
    "attributes": {
      "title": "B - Relacions amb els ciutadans i la societat"
    },
    "children": [
      {
        "id": 0,
        "level": 1,
        "attributes": {
          "title": "B.1.- Característiques de la Pàgina Web de l´Ajuntament"
        },
        "children": []
      },
      {
        "id": 1,
        "level": 1,
        "attributes": {
          "title": "B.2.- Informació i Atenció al Ciutadà"
        },
        "children": []
      },
      {
        "id": 2,
        "level": 1,
        "attributes": {
          "title": "B.3.- Grau de compromís per a la Ciutadania"
        },
        "children": []
      }
    ]
  },
  {
    "id": 2,
    "level": 0,
    "attributes": {
      "title": "C - Transparència Econòmic-Financera"
    },
    "children": [
      {
        "id": 0,
        "level": 1,
        "attributes": {
          "title": "C.1.- Informació comptable i pressupostària"
        },
        "children": []
      },
      {
        "id": 1,
        "level": 1,
        "attributes": {
          "title": "C.2.- Transparència en els ingressos, despeses i deutes municipals"
        },
        "children": []
      }
    ]
  },
  {
    "id": 3,
    "level": 0,
    "attributes": {
      "title": "D - Transparència en les Contractacions i costos dels Serveis"
    },
    "children": [
      {
        "id": 0,
        "level": 1,
        "attributes": {
          "title": "D.1.- Procediments de contractació de serveis"
        },
        "children": []
      },
      {
        "id": 1,
        "level": 1,
        "attributes": {
          "title": "D.2.- Subministradors i costos dels serveis"
        },
        "children": []
      }
    ]
  },
  {
    "id": 4,
    "level": 0,
    "attributes": {
      "title": "E - Transparència en matèries d´Urbanisme, Obres Públiques i Medi Ambient"
    },
    "children": [
      {
        "id": 0,
        "level": 1,
        "attributes": {
          "title": "E.1.- Plans d´ordenació urbana i convenis urbanístics"
        },
        "children": []
      },
      {
        "id": 1,
        "level": 1,
        "attributes": {
          "title": "E.2.- Anuncis i licitacions d´obres públiques"
        },
        "children": []
      },
      {
        "id": 2,
        "level": 1,
        "attributes": {
          "title": "E.3.- Informació sobre concurrents, ofertes i resolucions"
        },
        "children": []
      },
      {
        "id": 3,
        "level": 1,
        "attributes": {
          "title": "E.4.- Obres Publiques, Urbanisme i Infraestructura"
        },
        "children": []
      }
    ]
  },
  {
    "id": 5,
    "level": 0,
    "attributes": {
      "title": "F - Indicadors Llei de Transparència"
    },
    "children": [
      {
        "id": 0,
        "level": 1,
        "attributes": {
          "title": "F.1.- Planificació i organització de l´Ajuntament"
        },
        "children": []
      },
      {
        "id": 1,
        "level": 1,
        "attributes": {
          "title": "F.2.- Contractes, convenis i subvencions "
        },
        "children": []
      },
      {
        "id": 2,
        "level": 1,
        "attributes": {
          "title": "F.3.- Alts càrrecs de l´Ajuntament i Entitats participades"
        },
        "children": []
      },
      {
        "id": 3,
        "level": 1,
        "attributes": {
          "title": "F.4.- Informació econòmica i pressupostària"
        },
        "children": []
      }
    ]
  }
]

client = Savon.client(wsdl: WEBSERVICE_URL)

response = client.call(:consulta_indicadors, message: { peticio: {indicadornom: 'ITA14'}})
indicators = response.body.first.last.first.last.first.last

indicators.each do |indicator|
  indicador_nom = indicator[:indicadornom]
  indicador_nom_splitted = indicador_nom.split("ITA14.").last.split(".")

  ita_letter = (indicador_nom_splitted[0].ord - 65).to_i
  ita_number = indicador_nom_splitted[1].to_i - 1

  response = client.call(:consulta_valors_indicador, message: { peticio: {indicadordef: indicator[:indicadordef] }})

  value = !(response.body.first.last.first.last.first.last[:valor] == "En desenvolupament")  && !["118", "146"].include?(indicator[:indicadordef])
  indicator_splitted = indicator[:indicadordesc].split(".")
  id = indicator_splitted.first.to_i
  title = indicator[:indicadordesc]

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

  @ita14[ita_letter][:children][ita_number][:children].push({ id: id, level: 2, attributes: { title: title, checked: value, links: links }})
end

# Order arrays

@ita14.each do |letter|
  letter[:children].each do |number|
    number[:children] = number[:children].sort_by { |hsh| hsh[:id] }
  end
end


puts "[DEBUG] Generating indicators ITA 14..."

GobiertoIndicators::IndicatorsImporter.new("ita", @site, @ita14.to_json, @year).import!

puts "[END] import_ita14/run.rb"

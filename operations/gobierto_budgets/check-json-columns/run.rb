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
#
# Samples:
#
#   /path/to/project/operations/gobierto_budgets/check-json-columns/run.rb input.json
#

if ARGV.length != 1
  raise "At least one argument is required"
end

input_file = ARGV[0]

puts "[START] check-json-columns/run.rb with file=#{input_file}"

json_data = JSON.parse(File.read(input_file))

if json_data.length < 1
  puts "[ERROR] 0 rows of information"
  exit(-1)
end

row = json_data.first

unless row.is_a?(Hash)
  puts "[ERROR] row is not a Hash"
  exit(-1)
end

if row.keys.sort != ["any", "cap", "cap_desc", "fase", "fase_desc", "imp", "mes"] &&
    row.keys.sort != ["codi", "data", "des", "det", "ini", "num", "obs"] &&
    row.keys.sort != ["any", "area", "area_desc", "cap", "cap_desc", "dept", "dept_desc", "fase", "fase_desc", "imp", "mes", "prog", "prog_desc"]
  puts "[ERROR] row columns are not the expected"
  exit(-1)
end

puts "[END] check-json-columns/run.rb"

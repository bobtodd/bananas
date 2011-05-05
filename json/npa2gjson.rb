#!/usr/bin/env ruby

# A small script to read in NPA/NXX data, e.g.
# here:
#   http://www.infochimps.com/datasets/wire-centers-area-code-and-exchanges-usa-canada-npanxx
#
# and output GeoJSON.

require 'rubygems'
require 'rgeo/geo_json'

infile = File.new("npanxx.txt", "r")

while (line = infile.gets) do
  dataBits = line.match(/^(\d{3})\s*(\d{3})\s*(\d+\.\d+)\s*(\d+\.\d+)\s*(\D)\s*(\w+)\s*(\D+)$/)
  aPlace = {
    :npanxx => dataBits[1..2].join('-'),
    :lat    => dataBits[3].to_f,
    :long   => dataBits[4].to_f,
    :wire   => dataBits[5],
    :state  => dataBits[6],
    :city   => dataBits[7].split.join('-')  # Evidently RGeo or GeoJSON doesn't like spaces...
  }
  pointStr = "{\"type\": \"Point\", \"coordinates\": [#{aPlace[:lat]}, #{aPlace[:long]}]}"
  propStr  = "{"
  propStr += "\"npanxx\":\"#{aPlace[:npanxx]}\"" + ", "
  propStr += "\"state\":\"#{aPlace[:state]}\"" + ", "
  propStr += "\"city\":\"#{aPlace[:city]}\"" + ", "
  propStr += "\"use\":\"#{aPlace[:wire]}\""
  propStr += "}"
  str      = "{\"type\": \"Feature\", \"geometry\":#{pointStr}, \"properties\":#{propStr} }"
  puts str
  feature = RGeo::GeoJSON.decode(str, :json_parser => :json)
  puts feature["npanxx"]
  puts feature.geometry.as_text
end

infile.close

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
    :city   => dataBits[7]
  }
  puts aPlace[:city]
end

infile.close

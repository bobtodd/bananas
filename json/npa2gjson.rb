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
  puts line
end

infile.close

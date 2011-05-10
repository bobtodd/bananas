#!/usr/bin/env ruby

# A small script to read in NPA/NXX data, e.g.
# here:
#   http://www.infochimps.com/datasets/wire-centers-area-code-and-exchanges-usa-canada-npanxx
#
# and output GeoJSON.

require 'rubygems'
require 'rgeo/geo_json'

infile = File.new("npanxx.txt", "r")

# We want GeoJSON to know that our coordinates are [Long, Lat]
geofactory = RGeo::Geographic.spherical_factory

while (line = infile.gets) do
  # read each line and split info into an array
  dataBits = line.match(/^(\d{3})\s*(\d{3})\s*(\d+\.\d+)\s*(\d+\.\d+)\s*(\D)\s*(\w+)\s*(\D+)$/)
  
  # put info in a hash for easy access
  aPlace = {
    :npanxx => dataBits[1..2].join('-'),
    :lat    => dataBits[3].to_f,
    :long   => dataBits[4].to_f,
    :wire   => dataBits[5],
    :state  => dataBits[6],
    :city   => dataBits[7].split.join('-')  # Evidently RGeo or GeoJSON doesn't like spaces...
  }

  # packing all the data into a GeoJSON-formatted string
  pointStr = "{\"type\": \"Point\", \"coordinates\": [#{aPlace[:long]}, #{aPlace[:lat]}]}"
  propStr  = "{"
  propStr += "\"npanxx\":\"#{aPlace[:npanxx]}\"" + ", "
  propStr += "\"state\":\"#{aPlace[:state]}\"" + ", "
  propStr += "\"city\":\"#{aPlace[:city]}\"" + ", "
  propStr += "\"use\":\"#{aPlace[:wire]}\""
  propStr += "}"
  str      = "{\"type\": \"Feature\", \"geometry\":#{pointStr}, \"properties\":#{propStr} }"

  # recognizing the string as GeoJSON information
  feature = RGeo::GeoJSON.decode(str, :json_parser => :json, :geo_factory => geofactory)

  # taking the newly encoded GeoJSON info
  # and outputting in nice GeoJSON format
  hash = RGeo::GeoJSON.encode(feature)
  puts hash.to_json

  # now let's try just skipping the whole string-formatting by hand
  # (we want that to be automatic, don't we?)
  # and putting the input info into GeoJSON objects right from the start
  # cf. http://www.daniel-azuma.com/blog/archives/28

  loc = geofactory.point(aPlace[:long], aPlace[:lat])
  locHash = RGeo::GeoJSON.encode(loc)
  puts locHash.to_json

  muchProps = aPlace.reject{|key, val| key == :npanxx || key == :lat || key == :long}

  fLoc = RGeo::GeoJSON::Feature.new(loc, aPlace[:npanxx], muchProps)
  fLocHash = RGeo::GeoJSON.encode(fLoc)
  puts fLocHash.to_json
end

infile.close

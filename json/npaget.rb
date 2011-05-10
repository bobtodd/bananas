#!/usr/bin/env ruby

# This is a straightforward script designed to
# get a file of NPA/NXX data from the web and
# encode the entries in GeoJSON and output the
# result to a new file.

require 'rubygems'
require 'rgeo/geo_json'
require 'open-uri'

url   = 'http://www.wcisd.hpc.mil/~phil/npanxx/npanxx99.txt'
ifile = open(url)
# ifile = open('npanxx.txt', 'r')
ofile = File.open('npanxx_out.txt', 'w')

# We want GeoJSON to know that our coordinates are [Long, Lat]
geofactory = RGeo::Geographic.spherical_factory

while (line = ifile.gets) do
  # read each line and split info into an array
  data = line.match(/^(\d{3})\s*(\d{3})\s*(\d+\.\d+)\s*(\d+\.\d+)\s*(\D)\s*(\w+)\s*(.+)$/)
  
  # organizing the data
  place = {
    :npanxx => data[1..2].join('-'),
    :lat    => data[3].to_f,
    :long   => data[4].to_f,
    :wire   => data[5],
    :state  => data[6],
    :city   => data[7].split.join('-')  # Evidently RGeo or GeoJSON doesn't like spaces...    
  }

  id        = place[:npanxx]
  locale    = geofactory.point(place[:long], place[:lat])
  loc_props = place.reject{|key, val| key == :npanxx || key == :long || key == :lat}

  loc_feat  = RGeo::GeoJSON::Feature.new(locale, id, loc_props)
  loc_hash  = RGeo::GeoJSON.encode(loc_feat, :json_parser => :json, :geo_factory => geofactory)
  
  ofile.puts(loc_hash.to_json)
end

ifile.close
ofile.close

#!/usr/bin/env ruby

# Testing kmlite.rb

require './kmlite'

infilename  = ARGV[0]
outfilename = ARGV[1] # if nil, output will be to stdout

# create KMLdoc object
kdoc = KMLdoc.new(infilename)

# GeoJSONerize it!
kdoc.to_json(outfilename)

#!/usr/bin/env ruby

# Testing kmlite.rb

require './kmlite'

kdoc = KMLdoc.new(ARGV[0])

puts kdoc.placemarks.to_s

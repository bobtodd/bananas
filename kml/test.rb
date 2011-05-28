#!/usr/bin/env ruby

# Testing kmlite.rb

require './kmlite'

kdoc = KMLdoc.new(ARGV[0])

# kdoc.to_json('quicktest.txt')
kdoc.to_json

#!/usr/bin/env ruby

# Simple script to read an input file
# and spit out something JSONesque.
# Lord help us!

# See example of creating JSON at
# http://flori.github.com/json/doc/index.html

require 'rubygems'
require 'json'

theStuff = Array.new

infile = File.new("crummy_input.txt", "r")
while (line = infile.gets)
  # read file contents into a hash... er, an array... ?
  theStuff << line.split(':')
end
infile.close

puts theStuff

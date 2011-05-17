#!/usr/bin/env ruby

# Simple script to read an input file
# and spit out something JSONesque.
# Lord help us!

# See example of creating JSON at
# http://flori.github.com/json/doc/index.html

require 'rubygems'
require 'json'

theStuff = Array.new

infile = File.new("../tmp/crummy_input.txt", "r")
while (line = infile.gets)
  # read file contents into a hash... er, an array... ?
  if line.include? ':'
    verbiage = Hash.new
    thisKey, thisVal = line.split(':')
    verbiage[thisKey.strip] = thisVal.strip
    theStuff << verbiage
  elsif (line.chomp != "")
    theStuff << line.chomp
  end
end
infile.close

jout = JSON.pretty_generate theStuff

puts jout

#!/usr/bin/env ruby

require 'optparse'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: mackeyver.rb [OPTIONS] sourcefile"

  options[:keyfile] = 'state_key.txt'
  opts.on('-k', '--key FILE', "File containing state abbrevs.") do |file|
    options[:keyfile] = file
  end

  options[:output] = 'allStates.txt'
  opts.on('-o', '--out FILE', "Output filename") do |file|
    options[:output] = file
  end

  opts.on('-h', '--help', "Help display") do
    puts opts
    exit
  end
end


optparse.parse!

ifilename = ARGV[0]
ifile     = File.open(ifilename, "r")
kfilename = options[:keyfile]
kfile     = File.open(kfilename, "r")
ofilename = options[:output]
ofile     = File.open(ofilename, "w")

states = {}
while (line = kfile.gets) do
  key, value = line.split("\t")
  states[key] = value.chomp
end

# read infile line by line
# output the line you're on
# if that line contains a state abbrev., e.g. MT (Montana)
# then substitute the abbrev with alternate in options[:keyfile]
# output the new substituted line also

# Issue: MT also stands for Mountain Time... for crying out loud!
# Need to split line and only take abbrevs after "US"...
while (line = ifile.gets) do
  ofile.puts line
  firsthalf, secondhalf = line.split("\tUS\t")
  for key in states.keys
    abbrev = "\t" + key + "\t"
    if secondhalf.match(abbrev)
      newabbrev = "\t" + states[key] + "\t"
      ofile.puts firsthalf + "\tUS\t" + secondhalf.gsub(abbrev, newabbrev)
    end
  end
end

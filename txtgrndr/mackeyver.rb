#!/usr/bin/env ruby

# This little script is designed to flesh out a gazetteer
# (geographical data input for textgrounder) by duplicating
# those entries where the US statename could have an
# alternate abbreviation.

# E.g., the gazetteer lists Colorado as CO, but some use
# the abbreviation Colo.  So mackeyver.rb will take
# the gazetteer as the sourcefile, look at a list of
# abbreviations in another file (where "CO" is paired
# with "Colo"), take any line in the sourcefile containing
# "CO", and duplicate the entire line with "CO" replaced
# by "Colo".  Inelegant, I know.  But simple.

require 'optparse'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: mackeyver.rb [OPTIONS] sourcefile"

  options[:keyfile] = 'state_key.txt'
  opts.on('-k', '--key FILE', "File containing alternate state abbreviations.") do |file|
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
  key, the_rest = line.split("\t")
  values = the_rest.chomp.split(",")
  # values should be an array of abbreviations
  states[key] = values
end

# read infile line by line
# output the line you're on
# if that line contains a state abbrev., e.g. MT (Montana)
# then substitute the abbrev with alternate in options[:keyfile]
# output the new substituted line also

# Issue: MT also stands for Mountain Time... for crying out loud!
# Need to split line and only take abbrevs after "US"...

splitpoint = "\tUS\t"

while (line = ifile.gets) do
  ofile.puts line
  firsthalf, secondhalf = line.split(splitpoint)

  # If there's no "splitpoint" encountered, go to next line
  if !secondhalf
    next
  end

  # for each line in gazetter, go through each state in key-file
  for key in states.keys
    abbrev = "\t" + key + "\t"
    # find the current abbreviation in the gazetteer
    if secondhalf.match(abbrev)
      # if you find that state
      # replace it with each associated abbrev and output a duplicate line
      for name in states[key]
        newabbrev = "\t" + name + "\t"
        ofile.puts firsthalf + splitpoint + secondhalf.gsub(abbrev, newabbrev)
      end
    end
  end
end

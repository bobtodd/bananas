#!/usr/bin/env ruby

# A short script to run textgrounder MacGyver-style
# using low memory

require 'optparse'

# Use OptionsParser to read command-line options
options = {}

optparse = OptionParser.new do |opts|
  # Banner: displayed at top of help screen
  opts.banner = "Usage: macgyver.rb [options] infile"
  
  # Define options
  options[:country] = ""
  opts.on('-c', '--country [OPT]', "Country for data extraction") do |country|
    options[:country] = country || "US"
  end

  options[:random] = false
  opts.on('-r', '--random [N]', "Extract lines at random, up to a certain number") do |number|
    options[:random] = number.to_i || 10000
  end

  options[:outdir] = false
  opts.on('-d', '--directory DIR', "Directory for output") do |dir|
    options[:outdir] = dir
  end

  options[:source] = "pg4546.txt"
  opts.on('-s', '--source FILE', "Text file to parse") do |filename|
    options[:source] = filename
  end

  # The help screen
  opts.on('-h', '--help', 'Help display') do 
    puts opts
    exit
  end
end

# Parse the command line
# use "!" to have OptionsParser remove the entries in ARGV
# pertaining to options and their parameters
optparse.parse!

# get file with geographic info
# get the directory, filename, extension
infilename  = ARGV[0]
ifile       = File.open(infilename, "r")
base        = File.basename(infilename, File.extname(infilename))
ext         = File.extname(infilename)
dir         = options[:outdir] ? options[:outdir].chomp('/') : File.dirname(infilename)

# create file with extracted geographic info
suffix      = options[:country] ? "_" + options[:country] : ""
outfilename = dir + "/" + base + suffix
ofile       = File.open(outfilename + ext, "w")

# get path for textgrounder
tgpath      = ENV['TEXTGROUNDER_DIR']

puts "\nExtracting lines with geographic data..."
puts "Country: #{options[:country]}"

count = 0
total_count = 0
while (line = ifile.gets) do
  total_count += 1
  if options[:random] && (count < options[:random])
    random = rand(2)
    if random == 1
      ofile.puts line
      count += 1
    end
  elsif line =~ Regexp.new(options[:country])
    ofile.puts line
    count += 1
  elsif !ifile.gets
    break
  end
end

puts "\n#{count} lines extracted out of #{total_count}...\n"


# zip the file
puts "\nZipping geographic data file for processing...\n"
zipit = `zip #{outfilename}.zip #{outfilename}.txt`

# Now follow the textgrounder Getting Started instructions
# beginning with
# Step 7: Import GeoNames gazetteer
puts "\nImporting GeoNames gazetteer...\n"
puts %x[#{tgpath}/bin/textgrounder 4 import-gazetteer -i #{outfilename}.zip -o #{dir}/geonames#{suffix}.ser.gz -dkm 2>&1].inspect

# Step 9: preprocess the corpus
puts "\nPreprocessing the corpus...\n"
puts %x[#{tgpath}/bin/textgrounder 4 import-corpus -i #{options[:source]} -sg #{dir}/geonames#{suffix}.ser.gz -sco #{dir}/corpus#{suffix}.ser.gz 2>&1].inspect

# Step 10: detect and resolve toponyms
puts "\nDetecting and resolving toponyms...\n"
puts %x[#{tgpath}/bin/textgrounder 2 resolve -sci #{dir}/corpus#{suffix}.ser.gz -r BasicMinDistResolver -o #{dir}/widger#{suffix}.xml -ok #{dir}/widger#{suffix}.kml -sco #{dir}/resolved-corpus#{suffix}.ser.gz -sg #{dir}/geonames#{suffix}.ser.gz 2>&1].inspect

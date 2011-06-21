#!/usr/bin/env ruby

# A short script to run textgrounder MacGyver-style
# using low memory

require 'nokogiri'
require 'open-uri'
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

  options[:parse] = "//p"
  opts.on('-p', '--parse HTML', "Input string for Nokogiri's xpath() to parse HTML file") do |html|
    options[:parse] = html
  end

  options[:random] = false
  opts.on('-r', '--random [N]', "Extract lines at random, up to a certain number") do |number|
    options[:random] = number.to_i || 10000
  end

  options[:memory] = 4
  opts.on('-m', '--memory N', "Amount of memory (in GB) to use for processing") do |number|
    options[:memory] = number.to_i
  end

  options[:resolver] = "BasicMinDistResolver"
  opts.on('-r', '--resolver RES', "Type of algorithm for resolving toponyms") do |resolver|
    options[:resolver] = resolver
  end

  options[:iterations] = ""
  opts.on('-i', '--iterations [N]', "Number of iterations for a Weighted Minimum Distance algorithm") do |n|
    options[:iterations] = n.to_i || 10
  end

  options[:outdir] = false
  opts.on('-d', '--directory DIR', "Directory for output") do |dir|
    options[:outdir] = dir
  end

  options[:output] = "widger"
  opts.on('-o', '--output NAME', "Filename for KML output file") do |filename|
    options[:output] = filename
  end

  options[:geo] = ""
  opts.on('-g', '--geo FILE', "Text file containing raw geographic data") do |filename|
    options[:geo] = filename
  end

  options[:web] = false
  opts.on('-w', '--web', "Denotes that source file is a webpage") do
    options[:web] = true
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

# get path for textgrounder
tgpath      = ENV['TEXTGROUNDER_DIR']
datapath    = tgpath.chomp('/') + "/data/gazetteers/"
resolver    = options[:resolver] == ("WeightedMinDistResolver" || "wmd" || "WMD") ? \
                "WeightedMinDistResolver" : "BasicMinDistResolver"
iters       = options[:iterations] == "" ? options[:iterations] : "-it #{options[:iterations]}"

# get file with geographic info
# get the directory, filename, extension
geofilename = options[:geo] == "" ? datapath + "allCountries.txt" : options[:geo]
gfile       = File.open(geofilename, "r")
gbase       = File.basename(geofilename, File.extname(geofilename))
gext        = File.extname(geofilename)
gsfx        = options[:country] ? "_" + options[:country] : ""

dir         = options[:outdir] ? options[:outdir].chomp('/') : File.dirname(srcfilename)

# Now that OptionsParser has popped off the other elements of ARGV,
# we can write...
srcfilename = ARGV[0]

if options[:web]
  # a good example webpage is
  #   http://travel.nationalgeographic.com/travel/hotels/2009/best-hotels-western-us/
  wbpg        = Nokogiri::HTML(open(srcfilename))
  webfilename = dir + "/websource" + gsfx + ".txt"
  wfile       = File.open(webfilename, "w")

  # just output text between <p>...</p> tags in webpage
  # Thanks to Nokogiri, this is easy
  xmlpath = "#{options[:parse]}"
  wbpg.xpath(xmlpath).each do |paragraph|
    wfile.puts paragraph
  end

  # set the source to websource.txt
  srcfilename = webfilename
end

sfile       = File.open(srcfilename, "r")

# create file with extracted geographic info
ogfilename  = dir + "/" + gbase + gsfx
ogfile      = File.open(ogfilename + gext, "w")


puts "\nExtracting lines with geographic data..."
puts "Country: #{options[:country]}"

count = 0
total_count = 0
while (line = gfile.gets) do
  total_count += 1
  if options[:random] && (count < options[:random])
    random = rand(2)
    if random == 1
      ogfile.puts line
      count += 1
    end
  elsif line =~ Regexp.new(options[:country])
    ogfile.puts line
    count += 1
  elsif !gfile.gets
    break
  end
end

puts "\n#{count} lines extracted out of #{total_count}...\n"


# zip the file
puts "\nZipping geographic data file for processing...\n"
zipit = `zip #{ogfilename}.zip #{ogfilename}.txt`

# Now follow the textgrounder Getting Started instructions
# beginning with
# Step 7: Import GeoNames gazetteer
puts "\nImporting GeoNames gazetteer...\n"
puts %x[#{tgpath}/bin/textgrounder #{options[:memory]} import-gazetteer -i #{ogfilename}.zip -o #{dir}/geonames#{gsfx}.ser.gz -dkm 2>&1].inspect

# Step 9: preprocess the corpus
puts "\nPreprocessing the corpus...\n"
puts %x[#{tgpath}/bin/textgrounder #{options[:memory]} import-corpus -i #{srcfilename} -sg #{dir}/geonames#{gsfx}.ser.gz -sco #{dir}/corpus#{gsfx}.ser.gz 2>&1].inspect

# Step 10: detect and resolve toponyms
puts "\nDetecting and resolving toponyms...\n"
puts %x[#{tgpath}/bin/textgrounder #{options[:memory]/2} resolve -sci #{dir}/corpus#{gsfx}.ser.gz -r #{resolver} #{iters} -o #{dir}/#{options[:output]}#{gsfx}.xml -ok #{dir}/#{options[:output]}#{gsfx}.kml -sco #{dir}/resolved-corpus#{gsfx}.ser.gz -sg #{dir}/geonames#{gsfx}.ser.gz 2>&1].inspect

#!/usr/bin/env ruby

# A short script to run textgrounder MacGyver-style
# first extracting only info from the U.S.

# Usage:
# ./tg_us file_from_which_to_extract_lines.txt output_directory

# read in a number of lines to extract
# and a file to extract them from

infilename  = ARGV[0]
ifile       = File.open(infilename, "r")
base        = File.basename(infilename, File.extname(infilename))
ext         = File.extname(infilename)
dir         = ARGV[1]
suffix      = "_us"
outfilename = dir + "/" + base + suffix
ofile       = File.open(outfilename + ext, "w")
tgpath      = ENV['TEXTGROUNDER_DIR']

# put "number" lines in a new file
# but let's make it a random sample of "number" lines
puts "Extracting lines with U.S. data..."
count = 0
total_count = 0
while (line = ifile.gets) do
  total_count += 1
  if line =~ /America/  # e.g. Chicago is listed as America/Chicago
    ofile.puts line
    count += 1
  elsif !ifile.gets
    break
  end
end

puts "#{count} lines extracted out of #{total_count}..."


# zip the file
zipit = `zip #{outfilename}.zip #{outfilename}.txt`

# Now follow the textgrounder Getting Started instructions
# beginning with
# Step 7: Import GeoNames gazetteer
puts %x[#{tgpath}/bin/textgrounder 4 import-gazetteer -i #{outfilename}.zip -o #{dir}/geonames#{suffix}.ser.gz -dkm 2>&1].inspect

# Step 9: preprocess the corpus
puts %x[#{tgpath}/bin/textgrounder 4 import-corpus -i pg4546.txt -sg #{dir}/geonames#{suffix}.ser.gz -sco #{dir}/corpus#{suffix}.ser.gz 2>&1].inspect

# Step 10: detect and resolve toponyms
puts %x[#{tgpath}/bin/textgrounder 2 resolve -sci #{dir}/corpus#{suffix}.ser.gz -r BasicMinDistResolver -o #{dir}/widger#{suffix}.xml -ok #{dir}/widger#{suffix}.kml -sco #{dir}/resolved-corpus#{suffix}.ser.gz -sg #{dir}/geonames#{suffix}.ser.gz 2>&1].inspect

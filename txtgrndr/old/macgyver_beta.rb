#!/usr/bin/env ruby

# A short script to run textgrounder MacGyver-style
# on low memory

# Usage:
# ./macgyver number file_from_which_to_extract_lines.txt

# read in a number of lines to extract
# and a file to extract them from

number      = ARGV[0].to_i
ifile       = File.open(ARGV[1], "r")
base        = File.basename(ARGV[1], File.extname(ARGV[1]))
ext         = File.extname(ARGV[1])
outfilename = base + "_head"
ofile       = File.open(outfilename + ext, "w")
tgpath      = ENV['TEXTGROUNDER_DIR']

# put "number" lines in a new file
# but let's make it a random sample of "number" lines
puts "Getting random sample of #{number} lines..."
count = 0
total_count = 0
while (count < number) do
  random = rand(2)
  total_count += 1
  if random == 1
    ofile.puts ifile.gets
    count += 1
  elsif !ifile.gets
    break
  end
end

puts "#{count} lines read out of #{total_count} iterations..."


# zip the file
zipit = `zip #{outfilename}.zip #{outfilename}.txt`

# Now follow the textgrounder Getting Started instructions
# beginning with
# Step 7: Import GeoNames gazetteer
puts %x[#{tgpath}/bin/textgrounder 4 import-gazetteer -i #{outfilename}.zip -o geonames_head.ser.gz -dkm 2>&1].inspect

# Step 9: preprocess the corpus
puts %x[#{tgpath}/bin/textgrounder 4 import-corpus -i pg4546.txt -sg geonames_head.ser.gz -sco corpus_head.ser.gz 2>&1].inspect

# Step 10: detect and resolve toponyms
puts %x[#{tgpath}/bin/textgrounder 2 resolve -sci corpus_head.ser.gz -r BasicMinDistResolver -o widger_head.xml -ok widger_head.kml -sco resolved-corpus_head.ser.gz -sg ../data/gazetteers/geonames.ser.gz 2>&1].inspect

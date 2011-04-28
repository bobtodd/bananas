#!/usr/bin/env ruby

# basic script to read a file
# source code at http://www.abbeyworkshop.com/howto/ruby/rb-readfile/index.html

# Example 1 - Read file and close
counter = 1
file = File.new("read_file.rb", "r")
while (line = file.gets)             # readline() returns error at EOF, gets() returns nil
  puts "#{counter}: #{line}"
  counter = counter + 1
end
file.close

# Example 2 - Pass file to block
counter = 1
File.open("read_file.rb", "r") do |infile| # new() creates file object, open() doesn't
  while (line = infile.gets)
    puts "#{counter}: #{line}"
    counter = counter + 1
  end
end

# Example 3 - Read File with Exception Handling
counter = 1
begin
  file = File.new("read_file.rb", "r")
  while (line = file.gets)
    puts "#{counter}: #{line}"
    counter = counter + 1
  end
  file.close
rescue => err
  puts "Exception: #{err}"
  err
end

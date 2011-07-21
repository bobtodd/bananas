#!/usr/bin/env ruby

# A script to download soccer stats from here:
#   http://www.rsssf.com/

# How do we want the data to look?
# Maybe everything should be a match with the follow structure...
#   Round Group Date Location Home_Team Score Away_Team


# an array of matches
class Tournament
  attr_accessor :text
  
  def initialize(text)
    @text = clean(text)
  end

  def clean(text)
    return text.to_s.gsub(/<\D*>/,'')
  end
  
  def find_phases()
    phases = []
    @text.split(/FINAL|MATCH/).each do |phase|
      phases << phase.strip
    end
    return phases
  end
end

class Phase
  attr_accessor :text
  
  def initialize(text)
    @text = clean(text)
  end

  def clean(text)
    return
  end
end

class Group
end

class Match
end

require 'nokogiri'
require 'open-uri'

sourcepage = ARGV[0]

wbpg = Nokogiri::HTML(open(sourcepage))
title = ""
wbpg.xpath("//title").each do |the_title|
  title = the_title.to_s.downcase.gsub(/<\D*>/,'').gsub(' ', '_')
end

outfilename = title + '.csv'
puts "outfilename: #{outfilename}"

wbpg.xpath("//pre").each do |text|
  tourney = Tournament.new(text)
  # puts tourney.text
  phases = tourney.find_phases
  puts phases[0]
end

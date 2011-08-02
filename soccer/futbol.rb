#!/usr/bin/env ruby

# A script to download soccer stats from here:
#   http://www.rsssf.com/

# How do we want the data to look?
# Maybe everything should be a match with the follow structure...
#   Round Group Date Location Home_Team Score Away_Team


# an array of matches
class Tournament
  attr_accessor :name, :text
  
  def initialize(name, text)
    @name = name
    @text = clean(text)
  end

  def clean(text)
    return text.to_s.gsub(/<\D*>/,'')
  end
  
  def find_phases()
    # Find titles of phases
    break_here = /[A-Z]*\s*PHASE|[A-Z]*\s*[A-Z]+\s*MATCH|[\dA-Z]*.*FINAL[S]*/
    breakpoints = @text.scan(break_here)
    
    # create a hash for the phases:
    # key="NAME OF PHASE", value=phase_text
    phases = []
    for i in 0...breakpoints.length-1
      # take stuff after this breakpoint
      garbage, useful_text = @text.split(breakpoints[i])
      # throw away stuff after the next breakpoint
      useful_text, garbage = useful_text.split(breakpoints[i+1])
      # tack on what's left to the phases hash
      phases << Phase.new(breakpoints[i], useful_text.strip)
    end

    # tack on the text after the last breakpoint
    phases << Phase.new(breakpoints.last, garbage.strip)
    return phases
  end
end

class Phase
  attr_accessor :name, :text
  
  def initialize(name, text)
    @name = name
    @text = clean(text)
  end

  def clean(text)
    return text.to_s
  end
  
  def find_groups()
    # create an array of groups
    groups = []
    
    if @name =~ /FIRST/
      # Find titles of groups
      break_here = /Group\s+[A-Z]/
      breakpoints = @text.scan(break_here)
    
      for i in 0...breakpoints.length-1
        puts "\tWorking on #{breakpoints[i]}" + "\t"*i + "..."
        garbage, useful_text = @text.split(breakpoints[i])
        useful_text, garbage = useful_text.split(breakpoints[i+1])
        
        its_a_keeper = ""
        useful_text.each_line do |line|
          its_a_keeper << line unless line =~ /^\s\d\.[A-Z]+/
        end
        
        groups << Group.new(breakpoints[i], its_a_keeper.strip)
      end
      
      puts "\tWorking on #{breakpoints.last}..."
      tail = ""
      garbage.each_line do |line|
        tail << line unless line =~ /^\s\d\.[A-Z]+/
      end
      
      groups << Group.new(breakpoints.last, tail.strip)
    elsif @name != "FINAL"
      # Not in FIRST PHASE, but
      # not the FINAL either
      puts "No longer FIRST PHASE......"
      no_blanks = ""
      @text.each_line do |line|
        no_blanks << line unless line =~ /^\s*$/
      end
      groups << Group.new("#{@name}", no_blanks)
    else
      # Must be FINAL phase
      only_useful_lines = ""
      @text.each_line do |line|
        only_useful_lines << line if line =~ /\w+[,]\s\w+\s\d\d[,]|\w+\s+\d[-]\d\s+\w+/
      end
      groups << Group.new("#{@name}", only_useful_lines)
    end
    
    return groups
  end
end

class Group
  attr_accessor :name, :text
  
  def initialize(name, text)
    @name = name
    @text = text
  end
end

class Match
end

require 'nokogiri'
require 'open-uri'

sourcepage = ARGV[0] != nil ? ARGV[0] : "http://www.rsssf.com/tables/2010f.html"

wbpg = Nokogiri::HTML(open(sourcepage))
title = ""
wbpg.xpath("//title").each do |the_title|
  title = the_title.to_s.downcase.gsub(/<\D*>/,'').gsub(' ', '_')
end

outfilename = title + '.csv'
puts "outfilename: #{outfilename}"

wbpg.xpath("//pre").each do |text|
  tourney = Tournament.new(title, text)
  # puts tourney.text
  phases = tourney.find_phases
  for ph in phases
    puts "Phase #{ph.name}: finding groups..."
    groups = ph.find_groups
    groups.each do |grp|
      puts "Phase #{ph.name}: #{grp.name}:\n#{grp.text}"
    end
  end
end

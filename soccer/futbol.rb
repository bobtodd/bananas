#!/usr/bin/env ruby

# A script to download soccer stats from here:
#   http://www.rsssf.com/

# How do we want the data to look?
# Maybe everything should be a match with the follow structure...
#   Round Group Date Location Home_Team Score Away_Team


# an array of matches
class Tournament
  attr_accessor :name, :text, :phases
  
  def initialize(name, text)
    @name   = name
    @text   = clean(text)
    @phases = find_phases
  end

  def clean(text)
    return text.to_s.gsub(/<\D*>/,'')
  end
  
  def find_phases()
    # Find titles of phases
    break_here = /[A-Z]*\s*PHASE|[A-Z]*\s*[A-Z]+\s*MATCH|[\dA-Z]*.*FINAL[S]*/
    breakpoints = @text.scan(break_here)
    
    # create an array for the phases, each entry as follows:
    # ["NAME OF PHASE", phase_text], or more simply,
    # each entry an instance of the Phase class
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
  
  def to_s
    outstr = ""
    @phases.each { |ph| outstr += ph.to_s + "\n" }
    return outstr
  end
end

class Phase
  attr_accessor :name, :text, :groups
  
  def initialize(name, text)
    @name   = name
    @text   = clean(text)
    @groups = find_groups
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
        #puts "\tWorking on #{breakpoints[i]}" + "\t"*i + "..."
        garbage, useful_text = @text.split(breakpoints[i])
        useful_text, garbage = useful_text.split(breakpoints[i+1])
        
        its_a_keeper = ""
        useful_text.each_line do |line|
          its_a_keeper << line unless line =~ /^\s\d\.[A-Z]+/
        end
        
        groups << Group.new(breakpoints[i], its_a_keeper.strip)
      end
      
      #puts "\tWorking on #{breakpoints.last}..."
      tail = ""
      garbage.each_line do |line|
        tail << line unless line =~ /^\s\d\.[A-Z]+/
      end
      
      groups << Group.new(breakpoints.last, tail.strip)
    elsif @name != "FINAL"
      # Not in FIRST PHASE, but
      # not the FINAL either
      #puts "No longer FIRST PHASE......"
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
  
  def to_s
    outstr = ""
    @groups.each { |grp| outstr += grp.to_s + "\n" }
    return outstr
  end
end

class Group
  attr_accessor :name, :text, :games
  
  def initialize(name, text)
    @name  = name
    @text  = text
    @games = find_games
  end
  
  def find_games()
    # more or less, each line is a game
    games = []
    
    if @name =~ /Group\s[A-Z]/
      @text.each_line do |line|
        date, text = line.scan(/(\s*\d+[-]\s*\d+[-]\d+)\s+(.+)$/)[0]
        games << Game.new("#{@name}", date, text.strip)
      end
    elsif @name =~ /FINAL(?!S)/
      location = ""
      date = ""
      text = ""
      @text.each_line do |line|
        if line =~ /^\w+[,]\s\w+\s\d+[,]\s\d+/
          location, date = line.scan(/^(\w+)[,]\s(\w+\s\d+[,]\s\d+)/)[0]
        else
          text << location + "   " + line.strip
        end
      end
      games << Game.new("#{@name}", date, text)
    else
      @text.each_line do |line|
        if line =~ /^[\s\d]\d/
          date, text = line.scan(/(\s*\d+[-]\s*\d+[-]\d+)\s+(.+)$/)[0]
          games << Game.new("#{@name}", date, text.strip)
        end
      end
    end
    
    return games
  end
  
  def to_s
    outstr = ""
    @games.each { |gm| outstr += gm.to_s + "\n" }
    return outstr
  end
end

class Game
  attr_accessor :name, :date, :text, :location, :home, :home_pts, :away, :away_pts, :notes
  
  def initialize(name, date, text)
    @name = name
    @date = date
    @text = text.strip
    @location, @home, @home_pts, @away, @away_pts, @notes = sift
  end
  
  def sift
    data = []
    location           = @text[0..13].strip
    home               = @text[15..26].strip
    home_pts, away_pts = @text.scan(/(\d+)[-](\d+)/)[0]
    away               = @text[37..49]
    notes              = @text[50..-1] ? @text[50..-1].strip : ""
    data << location
    data << home
    data << home_pts
    data << away
    data << away_pts
    data << notes
  end
  
  def score
    puts @home + " " + @home_pts + "-" + @away_pts + " " + @away
  end
  
  def to_s
    outstr  = @name     + "\t"
    outstr += @date     + "\t"
    outstr += @location + "\t"
    outstr += @home     + "\t"
    outstr += @home_pts + "\t"
    outstr += @away     + "\t"
    outstr += @away_pts + "\t"
    outstr += @notes
  end
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
  puts tourney.to_s
end

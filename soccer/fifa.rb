#!/usr/bin/env ruby

# The problem with http://www.rsssf.com/ is that the data is
# pure text (good!), but *visually* formatted (bad!!!):
# that is, there are just spaces between data elements, so
# that a human can read the entries.  There's no other
# marking; and worse, even the spacing is *inconsistent*
# across different files, so one tournament will have a
# different data layout from another.  Ugh.

# So now we're going to try to cull data from www.fifa.com.
# That seems to be a robust (stats of various types, e.g.
# scores, player data, etc.) and deep (going back to 1930)
# data set.  It's couched in HTML, the bane of my existence,
# but at least that means different data are tagged by
# different keywords.  So I should be able to extract info
# automatically.

# EOD (End Of Diatribe)

# Basic data location:
#   http://www.fifa.com/worldfootball/statisticsandrecords/
# Even better, note the archives:
#   http://www.fifa.com/worldcup/archive/edition=1/results/index.html
# and increment "edition=" by 1 to get additional results.
# Similarly:
#   http://www.fifa.com/worldfootball/statisticsandrecords/players/player=25113/index.html
# and increment the "player=".
# Also:
#   http://www.fifa.com/worldfootball/statisticsandrecords/associations/association=can/worldcup/index.html
# and change the "association=" to "ger", say, for Germany.

require 'open-uri'
require 'nokogiri'
require 'json'

# get_category() looks for the next-higher level
# HTML-tag that describes the category to which the
# current table belongs.  E.g. if we have a table
# of matches, do these belong to the "Results" of
# a World Cup tournament, or are they, say, UEFA
# league-level results?  The FIFA websites put in
# league-level data as <h2>-headers, but it's not
# consistent.
def get_category(block, style)
  unless block.nil?
    if block.name == style
      return block
    else
      get_category(block.previous, style)
    end
  else
    return false
  end
end

class Match
  attr_accessor :source, :category, :round, :match, :date, :home_team, :results, :away_team
  
  def to_s
    JSON.pretty_generate({
      :source    => @source,
      :category  => @category,
      :round     => @round,
      :match     => @match,
      :date      => @date,
      :home_team => @home_team,
      :results   => @results,
      :away_team => @away_team
    })
  end
  
  def to_json
    {
      :source    => @source,
      :category  => @category,
      :round     => @round,
      :match     => @match,
      :date      => @date,
      :home_team => @home_team,
      :results   => @results,
      :away_team => @away_team
    }.to_json
  end
end

class Tourney
  attr_accessor :title, :matches

  def initialize(title='', matches=[])
    @title   = title
    @matches = matches
  end
  
  def to_s
    JSON.pretty_generate({
      :title   => @title,
      :matches => @matches.map{ |item| item.to_s}
    })
  end
  
  def to_json
    {
      :title   => @title,
      :matches => @matches.to_s
    }.to_json
  end
end

pagehits = []
1.upto(20) do |i|
  pagehits << "http://www.fifa.com/worldcup/archive/edition=#{i}/results/index.html"
end

ofile = File.open("../tmp/fifa_stats.txt", 'w')

# Store a regex we'll be using a lot...
in_tags = /<[^>]+>([^<]*)<[^>]+>/

pagehits.each do |hit|  
  page = Nokogiri::HTML(open(hit))
  
  # trny = Tourney.new(tables.xpath('//title').to_s.scan(/<[^>]+>([^<]*)<[^>]+>/)[0][0])
  title     = page.xpath('//div[@class = " title "]/h1').to_s.scan(in_tags)[0][0]
  minititle = page.xpath('//h1[@class = "miniTitle "]').to_s.scan(in_tags)[0][0]
  trny      = Tourney.new(title)
  
  # If you want to check what page you're on, uncomment:
  puts hit

  # try '//table[@summary = "Group 1"]' for only Group 1 tables
  
  # tables with group standings are labeled class="groupsStandig"
  # but tables with raw match data are class="fixture"
  # we just want the raw data (we can generate the stats ourselves)
  
  fixtures   = page.xpath('//div[@class = "fullpageFixtures"]')
  categories = fixtures.xpath('h2')
  puts "\tCategories:"
  categories.each { |x| puts "\t\t#{x}"}
  
  # for each table...
  page.xpath('//table[@class = "fixture"]').each do |tbl|
    # get the category...
    has_category = get_category(tbl, 'h2').to_s.scan(in_tags)[0]
    category     = has_category ? has_category[0] : ''
    puts "."*20 + "\tCategory: #{category}"
    
    # get the table title...
    has_caption = tbl.xpath('caption').to_s.scan(in_tags)[0]
    caption     = has_caption ? has_caption[0] : ''
    
    # if you want to check what table you're in, uncomment:
    puts "."*20 + "\tCaption: #{caption}"
    
    tbl.xpath('tbody/tr').each do |tr|
      # then get data for each match (i.e. for each row)
      match = Match.new
      match.source   = hit
      match.category = category
      match.round    = caption
            
      mNum            = 'td[@class = "c mNum"]'
      game            = tr.xpath(mNum + '/a').to_s.scan(in_tags)[0]
      match.match     = game ? game[0] : tr.xpath(mNum).to_s.scan(in_tags)[0][0]
      
      dt              = 'td[@class = "l dt"]'
      date            = tr.xpath(dt + '/a').to_s.scan(in_tags)[0]
      match.date      = date ? date[0] : tr.xpath(dt).to_s.scan(in_tags)[0][0]
      
      homeTeam        = 'td[@class = "l homeTeam"]'
      home            = tr.xpath(homeTeam + '/a').to_s.scan(in_tags)[0]
      match.home_team = home ? home[0] : tr.xpath(homeTeam).to_s.scan(in_tags)[0][0]
      
      empty           = 'td[@class = "c "]'
      score           = tr.xpath(empty + '/a').to_s.scan(in_tags)[0]
      match.results   = score ? score[0] : tr.xpath(empty).to_s.scan(in_tags)[0][0]
      
      awayTeam        = 'td[@class = "r awayTeam"]'
      away            = tr.xpath(awayTeam + '/a').to_s.scan(in_tags)[0]
      match.away_team = away ? away[0] : tr.xpath(awayTeam).to_s.scan(in_tags)[0][0]
      
      # add that to the tourney data
      trny.matches << match
    end
  end

  ofile.puts trny
end

ofile.close

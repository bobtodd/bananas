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

class Match
  attr_accessor :source, :round, :match, :date, :home_team, :results, :away_team
  
  def to_s
    JSON.pretty_generate({
      :source    => @source,
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
      :matches => @matches.to_s
    })
  end
  
  def to_json
    {
      :title   => @title,
      :matches => @matches
    }.to_json
  end
end

results = []
1.upto(10) do |i|
  results << "http://www.fifa.com/worldcup/archive/edition=#{i}/results/index.html"
  # for now, just get one page
  break
end

results.each do |result|  
  tables = Nokogiri::HTML(open(result))
  
  trny = Tourney.new(tables.xpath('//title').to_s.scan(/<[^>]+>([^<]*)<[^>]+>/)[0][0])

  # try '//table[@summary = "Group 1"]' for only Group 1 tables
  
  # tables with group standings are labeled class="groupsStandig"
  # but tables with raw match data are class="fixture"
  # we just want the raw data (we can generate the stats ourselves)
  
  # for each table...
  tables.xpath('//table[@class = "fixture"]').each do |tbl|
    # get the table title...
    caption = tbl.xpath('caption').to_s.scan(/<[^>]+>([^<]*)<[^>]+>/)[0][0]
    
    tbl.xpath('tbody/tr').each do |tr|
      # then get data for each match (i.e. for each row)
      match = Match.new
      match.source = result
      match.round  = caption
      
      match.match     = tr.xpath('td[@class = "c mNum"]').to_s.scan(/<[^>]+>([^<]*)<[^>]+>/)[0][0]
      match.date      = tr.xpath('td[@class = "l dt"]').to_s.scan(/<[^>]+>([^<]*)<[^>]+>/)[0][0]
      match.home_team = tr.xpath('td[@class = "l homeTeam"]/a').to_s.scan(/<[^>]+>([^<]*)<[^>]+>/)[0][0]
      match.results   = tr.xpath('td[@class = "c "]/a').to_s.scan(/<[^>]+>([^<]*)<[^>]+>/)[0][0]
      match.away_team = tr.xpath('td[@class = "r awayTeam"]/a').to_s.scan(/<[^>]+>([^<]*)<[^>]+>/)[0][0]
      
      # add that to the tourney data
      trny.matches << match
    end
  end
  
  puts trny
end


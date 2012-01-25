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

require 'optparse'
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

# A Match object contains all the data from a given
# FIFA soccer match.  Think of it as one row in a table,
# where you can access the columns by name.
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
  
  def to_json(*a)
    {
      :source    => @source,
      :category  => @category,
      :round     => @round,
      :match     => @match,
      :date      => @date,
      :home_team => @home_team,
      :results   => @results,
      :away_team => @away_team
    }.to_json(*a)
  end
end

# Tourney is just a glorified Array of all the matches.
# Each element in the Array is a Match object.  For added
# pleasure, each Tourney comes with a free title!
class Tourney
  attr_accessor :title, :matches

  def initialize(title='', matches=[])
    @title   = title
    @matches = matches
  end
  
  def to_s
    JSON.pretty_generate({
      :title   => @title,
      :matches => @matches.map{ |match| match.to_s}
    })
  end
  
  def to_json(*a)
    {
      :title   => @title,
      :matches => @matches.map{ |match| match.to_json(*a)}
    }.to_json(*a)
  end
end

# Read command-line options
options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: ./fifa.rb [options]"
  
  options[:start] = 1
  opts.on('-b', '--start N', "Page number to start (begin) scraping data") do |number|
    options[:start] = number.to_i
  end

  options[:stop] = 10
  opts.on('-e', '--stop N', "Page number to stop (end) scraping data") do |number|
    options[:stop] = number.to_i
  end
  
  options[:outfile] = "../tmp/fifa_stats.json"
  opts.on('-o', '--out FILE', "Name of JSON output file") do |filename|
    options[:outfile] = filename
  end
  
  opts.on('-h', '--help', 'Help display') do
    puts opts
    exit
  end
end

optparse.parse!

# Set start and stop points
a = options[:start]
b = options[:stop]
start, stop = (a < b) ? [a, b] : [b, a]

puts "Good to go..."

# Make a list of the web pages where the target data
# is stored.
pagehits = []
start.upto(stop) do |i|
  pagehits << "http://www.fifa.com/worldcup/archive/edition=#{i}/results/index.html"
end

puts "Created list of target pages."

# Prepare a file to hold the scraped data.
ofile = File.open(options[:outfile], 'w')

# Store a regex we'll be using a lot...
in_tags = /<[^>]+>([^<]*)<[^>]+>/

# Now go through each page one by one
pagehits.each do |hit|
  # Open the page
  page = Nokogiri::HTML(open(hit))
  
  # Get the page title and the subtitle
  title     = page.xpath('//div[@class = " title "]/h1').to_s.scan(in_tags)[0][0]
  minititle = page.xpath('//h1[@class = "miniTitle "]').to_s.scan(in_tags)[0][0]
  trny      = Tourney.new(title)
  
  # If you want to check what page you're on, uncomment:
  puts hit
  
  # Tables with group standings are labeled class="groupsStandig",
  # but tables with raw match data are class="fixture".
  # We just want the raw data (we can generate the stats ourselves)
  
  # Isolate raw data
  fixtures   = page.xpath('//div[@class = "fullpageFixtures"]')
  
  # There are sub-subtitles that precede data tables.
  # They give things like league titles, e.g. implicitly saying
  # that "the following tables are for the UEFA matches", etc.
  # But they only occur in some pages, not in others.  Annoying!
  # Let's find out what those sub-subtitles are:
  categories = fixtures.xpath('h2')
  puts "\tCategories:"
  categories.each { |x| puts "\t\t#{x}"}
  
  # Now let's actually extract the data from the tables.
  # For each table...
  page.xpath('//table[@class = "fixture"]').each do |tbl|
    # Get the category...
    has_category = get_category(tbl, 'h2').to_s.scan(in_tags)[0]
    category     = has_category ? has_category[0] : ''
    puts "."*20 + "\tCategory: #{category}"
    
    # Get the table title (sub-sub-subtitle)...
    has_caption = tbl.xpath('caption').to_s.scan(in_tags)[0]
    caption     = has_caption ? has_caption[0] : ''
    
    # (if you want to check what table you're in, uncomment:)
    puts "."*20 + "\t Caption: #{caption}"
    
    # Go through the table row by row
    tbl.xpath('tbody/tr').each do |tr|
      # Get data for each match (i.e. for each row)
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
      
      # Add that match to the tourney data
      trny.matches << match
    end
  end
  
  # Write the tournament data to file
  ofile.puts trny
end

# Close everything down
ofile.close

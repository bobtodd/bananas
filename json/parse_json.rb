#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# example code from http://developer.yahoo.com/ruby/ruby-json.html
# a simple script to pull some JSON text from the web
# and store it as a Ruby hash in memory

=begin
Use:
irb(main):001:0> require 'parse_json'
=> true
irb(main):002:0> news = news_search('ruby', 2)
=> {"ResultSet"=>... "totalResultsReturned"=>2}}
irb(main):003:0> news['ResultSet']['Result'].each{ |result|
irb(main):004:1* print "#{result['Title']} => #{result['Url']}}\n"
irb(main):005:1> }
Ruby Wafer death ruled a homicide => http://www.ksla.com/story/14532304/ruby-wafer-death-ruled-a-homicide}
Ruby: Party- Marathon durch Österreich => http://www.vienna.at/ruby-party-marathon-durch-oesterreich/news-20110428-03223461}
=> [...]
=end

require 'rubygems'  # shouldn't be necessary for Ruby 1.9
require 'json'
require 'net/http'

def news_search(query, results=10, start=1)
  base_url = "http://search.yahooapis.com/NewsSearchService/V1/newsSearch?appid=YahooDemo&output=json"
  url      = "#{base_url}&query=#{URI.encode(query)}&results=#{results}&start=#{start}"
  resp     = Net::HTTP.get_response(URI.parse(url))
  data     = resp.body

  # we convert the returned JSON to native Ruby
  # data structure - a hash
  result = JSON.parse(data)

  # if the hash has 'Error' as a key, we raise an error
  if result.has_key? 'Error'
    raise "web service error"
  end
  return result
end

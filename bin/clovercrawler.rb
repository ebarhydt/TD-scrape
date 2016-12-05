#!/usr/bin/env ruby

require_relative '../lib/smccrawler'
require_relative '../lib/smccrawler/page/base'

puts ''
puts '###########################################'
puts ''
puts 'Welcome to Clover Scraper!'
puts ''
puts '###########################################'
puts ''

Smccrawler::Crawler.run

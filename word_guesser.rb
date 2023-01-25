#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

uri = ENV["MONGODB_URI"]
if uri.nil?
  puts "mongordle: the Wordle lover's best friend"
  puts "usage:"
  puts "\tMONGODB_URI=mongodb+srv://..../wordle ruby word_guesser.rb \"WORDY xx^xx\""
  exit 0
end

client = Mongo::Client.new(uri)
collection = client[:words]

criteria = possible_matches(ARGV)

puts criteria.to_json

ids = collection.find(criteria, {:projection => {'_id': 1}}).collect{|d| d['_id']}.sort

ids.each do |id|
     puts id
end

puts collection.find(criteria, {:projection => {'_id': 1}}).count


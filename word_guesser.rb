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

def possible_matches(guesses_results)
    mongo_criteria = {}
    known_letters = []
    excluded_letters = []
    positional_excludes = []
    positional_include = []
    0.upto(4) { |i|
      positional_excludes[i] = []
      positional_include[i] = nil

    }
    last_word = ''

    guesses_results.each { |arg|
      word = arg.split(' ')[0]
      word_info = arg.split(' ')[1]

      word_info.chars.each_with_index { |c,i|
        letter = word[i]
        case c
          when '^' # exact position match
            positional_include[i] = letter
            known_letters << letter

          when 'x' # letter not in solution (or already right in another spot)
            excluded_letters << letter

            # exclude this letter from every position (though overridden on `^`)
            0.upto(4) { |n| positional_excludes[n] << letter }

          when '~' # letter in solution, not in this position
            positional_excludes[i] << letter
            known_letters << letter

          else
            raise "Unknown info character: #{c}"
          end

          last_word = word
      }
    }

    known_letters.uniq!
    excluded_letters = excluded_letters - known_letters # account for duplicate letters with one excluded
    mongo_criteria["letters"] = {'$nin': excluded_letters }
    mongo_criteria["letters"]['$all'] = known_letters if known_letters.size > 0
    0.upto(4) { |i|
      if positional_include[i]
        mongo_criteria["letter#{i+1}"] = {'$eq': positional_include[i] }
      else
        if (positional_excludes[i] - excluded_letters).size > 0
          mongo_criteria["letter#{i+1}"] = { '$nin': (positional_excludes[i] - excluded_letters) }
        end
      end
    }

    return mongo_criteria
end

criteria = possible_matches(ARGV)

puts criteria.to_json

collection.find(criteria, {:projection => {'_id': 1}}).each do |document|
     puts document['_id']
end

puts collection.find(criteria, {:projection => {'_id': 1}}).count


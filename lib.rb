require 'uri'
require 'net/http'
require 'json'

def grade(guess, answer)
    scratch = answer.clone
    g = '?????'
    guess.chars.each_with_index { |c,i| 
      #puts "#{answer},#{c},#{i},#{g}"
      if c == scratch[i]
        g[i] = '^'
        scratch[i] = '#'
      else
        pos = scratch.index(c)
        if !pos 
          g[i] = 'x'
        end
      end
    }

    g.chars.each_with_index { |c,i| 
      if c == '?'
        pos = scratch.index(guess[i])
        if pos
          g[i] = '~'
          scratch[pos] = '#'
        else
          g[i] = 'x'
        end
      end
    }

    return g
  end

  def get_all_words
    uri = URI('http://localhost:8983/solr/words/select?q=*:*&wt=csv&csv.header=false&rows=9999&fl=id')
    res = Net::HTTP.get_response(uri)
    raise "HTTP Issue #{res.value}: #{res.message}" if !res.is_a?(Net::HTTPSuccess)
    return res.body.split
  end

  def get_wordle_words
    # This is brittle, as NYT has changed the JavaScript sometimes
    
    #from https://www.nytimes.com/games/wordle/index.html => 
    #        https://www.nytimes.com/games-assets/v2/wordle.992893b2460f03f03add5caca08dd66106a32432.js

    uri = URI("https://www.nytimes.com/games-assets/v2/wordle.992893b2460f03f03add5caca08dd66106a32432.js")

    res = Net::HTTP.get_response(uri)
    raise "HTTP Issue #{res.value}: #{res.message}" if !res.is_a?(Net::HTTPSuccess)
    #puts res.body

    wordle_source_match = /ut\=\[(?<words>[^\]]*)\]/.match(res.body)

    wordle_source_match['words'].delete('"').upcase.split(',').sort
  end

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

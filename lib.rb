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
    #        https://www.nytimes.com/games-assets/v2/wordle.f3b467d34b755ef412d0411ab13998780171c617.js

    uri = URI("https://www.nytimes.com/games-assets/v2/wordle.f3b467d34b755ef412d0411ab13998780171c617.js")

    res = Net::HTTP.get_response(uri)
    raise "HTTP Issue #{res.value}: #{res.message}" if !res.is_a?(Net::HTTPSuccess)
    #puts res.body

    wordle_source_match = /_e\=\[(?<words>[^\]]*)\]/.match(res.body)

    wordle_source_match['words'].delete('"').upcase.split(',').sort
  end
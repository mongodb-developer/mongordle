require_relative 'lib'

word_list = get_wordle_words

docs = []

word_list.each do |word|  
  doc = { _id: word.strip, 
               letter1: word[0],
               letter2: word[1],
               letter3: word[2],
               letter4: word[3],
               letter5: word[4],
               four_chars: word.chars.each_with_index.collect { |c,i|
                 w = word.clone 
                 w[i] = '_'
                 w
               },
               letters: word.chars.uniq
             }
  docs << doc
end

puts JSON.dump(docs)
#puts word_list.size


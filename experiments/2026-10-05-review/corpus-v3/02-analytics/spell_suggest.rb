require "set"

def training_text
  "the quick brown fox jumps over the lazy dog the dog barks at the fox " +
  "a quick reply is better than a late reply the fox is quick and the dog is lazy " +
  "spelling errors are common when people type quickly and the correct word is often " +
  "one edit away from the typed word people often type the wrong letter or swap two letters " +
  "the dictionary counts how often each word appears so common words win ties"
end

def letters = "abcdefghijklmnopqrstuvwxyz"

def word_counts(text)
  counts = Hash.new(0)
  text.split(" ").each { |w| counts[w] += 1 }
  counts
end

def edits1(word)
  results = Set[]
  n = word.size
  0.upto(n) do |i|
    left = word[0, i]
    right = word[i, n - i]
    results << left + right[1, n] if right.size > 0
    if right.size > 1
      results << left + right[1] + right[0] + right[2, n]
    end
    letters.each_char do |c|
      results << left + c + right[1, n] if right.size > 0
      results << left + c + right
    end
  end
  results
end

def known(words, dict) = words.select { |w| dict.key?(w) }

def edits2_known(word, dict)
  found = Set[]
  edits1(word).each { |e1| edits1(e1).each { |e2| found << e2 if dict.key?(e2) } }
  found
end

def best(cands, dict)
  cands.to_a.sort.max_by { |w| dict[w] }
end

def correct(word, dict)
  return [word, 0] if dict.key?(word)
  one = known(edits1(word), dict)
  return [best(one, dict), 1] unless one.empty?
  two = edits2_known(word, dict)
  return [best(two, dict), 2] unless two.empty?
  [word, -1]
end

dict = word_counts(training_text)
puts "dictionary: #{dict.size} words, #{dict.values.sum} tokens"
puts "edits1('fox') has #{edits1("fox").size} candidates"

tests = ["teh", "quik", "dgo", "lazzy", "fxo", "speling", "dictonary", "the", "xyzzy", "brwn", "comon", "ofen"]
fixed = 0
cache = {}
tests.each do |t|
  cache[t] ||= correct(t, dict)
  w, dist = cache[t]
  label = case dist
          in 0 then "known"
          in 1 then "1 edit"
          in 2 then "2 edits"
          else "no suggestion"
          end
  fixed += 1 if dist > 0
  puts format("%-10s -> %-10s (%s)", t, w, label)
end
puts "corrected #{fixed} of #{tests.size}"

sentence = "teh quik brwn fxo jumsp ovr teh lazzy dgo"
out = sentence.split(" ").map do |t|
  cache[t] ||= correct(t, dict)
  w, _ = cache[t]
  w
end
puts "sentence: #{out.join(" ")}"
puts "cache size: #{cache.size}"

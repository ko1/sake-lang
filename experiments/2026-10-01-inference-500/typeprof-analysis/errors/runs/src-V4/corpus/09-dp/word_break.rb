require "set"

def dictionary(words) = Set[*words.split(" ")]

def max_word_length(dict) = dict.map(&:size).max

# can[i]: the prefix of length i splits into words
def breakable(text, dict)
  n = text.size
  longest = max_word_length(dict)
  can = Array.new(n + 1, false)
  can[0] = true
  1.upto(n) do |i|
    lo = [i - longest, 0].max
    lo.upto(i - 1) do |j|
      can[i] = true if can[j] && dict.include?(text[j...i])
    end
  end
  can[n]
end

def all_splits(text, dict, start, memo)
  cached = memo[start]
  return cached if cached
  result = []
  if start == text.size
    result << ""
  else
    (start + 1).upto(text.size) do |stop|
      word = text[start...stop]
      next unless dict.include?(word)
      all_splits(text, dict, stop, memo).each do |rest|
        result << (rest == "" ? word : "#{word} #{rest}")
      end
    end
  end
  memo[start] = result
end

# fewest words; ties broken by the earliest split
def fewest_words(text, dict)
  n = text.size
  best = Array.new(n + 1)
  cut = Array.new(n + 1, 0)
  best[0] = 0
  1.upto(n) do |i|
    0.upto(i - 1) do |j|
      prev = best[j]
      next if !prev    
      next unless dict.include?(text[j...i])
      cur = best[i]
      if !cur     || prev + 1 < cur
        best[i] = prev + 1
        cut[i] = j
      end
    end
  end
  return nil if !best[n]    
  words = []
  i = n
  while i > 0
    j = cut[i]
    words.unshift(text[j...i])
    i = j
  end
  words
end

dict = dictionary("a an and apple applepen pen pine pineapple cat cats dog dogs sand sea seashell shell shells sell sells he she by the shore or")
inputs = ["applepenapple", "pineapplepenapple", "catsanddog", "catsandog", "seashellsbytheseashore", "shesellsseashells", "andor", ""]

inputs.each do |text|
  ok = breakable(text, dict)
  puts "#{text.inspect}: #{ok ? "breakable" : "not breakable"}"
  next unless ok
  splits = all_splits(text, dict, 0, {})
  puts "  #{splits.size} way(s)"
  splits.sort.take(4).each { |s| puts "    #{s}" }
  puts "    ..." if splits.size > 4
  few = fewest_words(text, dict)
  puts "  fewest words: #{few.join(" | ")}" if few
end

hashtags = ["#lovesea", "#dogsandcats", "#pineapple", "#seashore"]
extra = dict | Set["love", "s"]
hashtags.each do |tag|
  body = tag.delete_prefix("#")
  words = fewest_words(body, extra)
  label = words ? words.map(&:capitalize).join(" ") : "(unsplittable)"
  puts "#{tag.ljust(14)} -> #{label}"
end

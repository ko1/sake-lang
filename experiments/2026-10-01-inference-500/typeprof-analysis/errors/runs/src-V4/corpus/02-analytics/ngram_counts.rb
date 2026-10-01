def text
  "the cat sat on the mat . the dog sat on the log . the cat saw the dog . " +
  "the dog chased the cat off the mat . a cat and a dog sat on the mat together . " +
  "the cat sat on the dog ."
end

class Gram
  include Comparable
  attr_reader :key, :count

  def initialize(key, count)
    @key = key
    @count = count
  end

  def <=>(other)
    c = other.count <=> @count
    c == 0 ? @key <=> other.key : c
  end
end

def ngrams(tokens, n)
  counts = Hash.new(0)
  tokens.each_cons(n) { |window| counts[window.join(" ")] += 1 }
  counts
end

def pair_counts(tokens)
  counts = Hash.new(0)
  tokens.each_cons(2) do |a, b|
    next if a == "." || b == "."
    counts[[a, b]] += 1
  end
  counts
end

def ranked(counts)
  counts.map { |k, c| Gram.new(k, c) }.sort
end

def show_top(title, counts, limit)
  puts "== #{title} (#{counts.size} distinct) =="
  ranked(counts).take(limit).each do |g|
    puts format("  %-22s %2d", g.key, g.count)
  end
end

def successors(pairs)
  table = {}
  pairs.each do |(a, b), c|
    table[a] ||= Hash.new(0)
    table[a][b] += c
  end
  table
end

def next_word_probs(table, word)
  followers = table[word]
  return [] if !followers    
  total = followers.values.sum
  probs = followers.map { |w, c| [w, c * 1.0 / total] }
  probs.sort_by { |_, pr| 1.0 - pr }
end

tokens = text.split(" ")
puts "tokens: #{tokens.size}"
show_top("unigrams", ngrams(tokens, 1), 5)
show_top("bigrams", ngrams(tokens, 2), 6)
show_top("trigrams", ngrams(tokens, 3), 4)

pairs = pair_counts(tokens)
table = successors(pairs)
["the", "cat", "sat", "zebra"].each do |w|
  probs = next_word_probs(table, w)
  if probs.empty?
    puts "after '#{w}': (never seen)"
  else
    parts = probs.map { |nw, pr| "#{nw}=#{pr.round(2)}" }
    puts "after '#{w}': #{parts.join(" ")}"
  end
end

best = pairs.max_by { |_, c| c }
if best
  (a, b), c = best
  puts "most frequent pair: #{a} -> #{b} (#{c})"
end

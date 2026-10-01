require "set"

def sentences
  [
    "coffee with milk and sugar",
    "tea with milk",
    "green tea with honey",
    "black coffee no sugar",
    "coffee and cake in the morning",
    "tea and cake in the afternoon",
    "honey and lemon tea",
    "milk and honey",
    "espresso is strong coffee",
    "strong black tea",
    "sugar in coffee",
    "lemon cake with sugar"
  ]
end

def stop = Set["with", "and", "no", "in", "the", "is"]

def word_sets(sents)
  sents.map do |s|
    ws = Set[]
    s.split(" ").each { |w| ws << w unless stop.include?(w) }
    ws
  end
end

def pair_key(a, b) = a < b ? [a, b] : [b, a]

def count_all(sets)
  single = Hash.new(0)
  pairs = Hash.new(0)
  sets.each do |ws|
    words = ws.sort
    words.each { |w| single[w] += 1 }
    words.each_with_index do |a, i|
      words.drop(i + 1).each { |b| pairs[pair_key(a, b)] += 1 }
    end
  end
  [single, pairs]
end

def pmi(single, pairs, n, a, b)
  joint = pairs[pair_key(a, b)]
  return nil if joint == 0
  Math.log2(joint * n * 1.0 / (single[a] * single[b]))
end

def neighbors(pairs, word)
  result = {}
  pairs.each do |(a, b), c|
    if a == word
      result[b] = c
    elsif b == word
      result[a] = c
    end
  end
  result
end

sets = word_sets(sentences)
n = sets.size
single, pairs = count_all(sets)
puts "sentences: #{n}, words: #{single.size}, co-occurring pairs: #{pairs.size}"

frequent = single.keys.sort.select { |w| single[w] >= 3 }
puts "frequent words: " + frequent.map { |w| "#{w}(#{single[w]})" }.join(" ")

scored = []
pairs.each do |(a, b), c|
  next if c < 2
  score = pmi(single, pairs, n, a, b)
  scored << [a, b, c, score] if score
end
scored = scored.sort_by { |a, b, _, _| a + " " + b }
scored = scored.sort_by { |_, _, _, s| -s }
puts "pairs seen 2+ times, by PMI:"
scored.each { |a, b, c, s| puts format("  %-7s %-7s %d  %6.3f", a, b, c, s) }

["tea", "coffee", "honey", "water"].each do |w|
  nb = neighbors(pairs, w)
  if nb.empty?
    puts "#{w}: no neighbors"
    next
  end
  parts = nb.keys.sort.map do |o|
    v = pmi(single, pairs, n, w, o)
    format("%s:%.2f", o, v || 0.0)
  end
  puts "#{w}: #{parts.join(" ")}"
end

never = []
frequent.each_with_index do |a, i|
  frequent.drop(i + 1).each do |b|
    never << "#{a}/#{b}" if pmi(single, pairs, n, a, b).nil?
  end
end
puts "frequent words never together: #{never.join(", ")}"

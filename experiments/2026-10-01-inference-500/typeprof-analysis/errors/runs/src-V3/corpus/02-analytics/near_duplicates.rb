require "set"

def documents
  {
    "a" => "the quick brown fox jumps over the lazy dog near the river bank",
    "b" => "the quick brown fox jumped over the lazy dog near the river bank",
    "c" => "a quick brown fox jumps over a lazy dog by the river",
    "d" => "stock markets fell sharply on monday as investors worried about rates",
    "e" => "stock markets fell sharply on monday as investors fretted about rates",
    "f" => "the recipe calls for two cups of flour and a pinch of salt",
    "g" => "investors worried about rates as stock markets fell on monday",
    "h" => "the lazy dog slept near the river bank all afternoon"
  }
end

def shingles(text, k)
  result = Set[]
  text.split(" ").each_cons(k) { |w| result << w.join(" ") }
  result
end

def jaccard(a, b)
  union = (a | b).size
  return 0.0 if union == 0
  (a & b).size * 1.0 / union
end

def str_hash(s, seed)
  h = seed
  s.each_byte { |b| h = (h * 31 + b) % 1000003 }
  h
end

def minhash(set, seeds)
  seeds.map do |seed|
    set.map { |sh| str_hash(sh, seed) }.min
  end
end

def estimate(sig_a, sig_b)
  same = 0
  sig_a.each_with_index { |v, i| same += 1 if v == sig_b[i] }
  same * 1.0 / sig_a.size
end

def find(parent, x)
  while parent[x] != x
    parent[x] = parent[parent[x]]
    x = parent[x]
  end
  x
end

def union(parent, a, b)
  ra = find(parent, a)
  rb = find(parent, b)
  return if ra == rb
  if ra < rb
    parent[rb] = ra
  else
    parent[ra] = rb
  end
end

docs = documents
sh2 = docs.transform_values { |t| shingles(t, 2) }
seeds = [7, 13, 101, 997, 4093, 65537, 3, 17, 29, 31, 37, 41]
sigs = sh2.transform_values { |s| minhash(s, seeds) }
names = docs.keys.sort

names.each { |n| puts "#{n}: #{sh2[n].size} shingles" }

puts "pair   exact  minhash"
parent = {}
names.each { |n| parent[n] = n }
names.each_with_index do |a, i|
  names.drop(i + 1).each do |b|
    exact = jaccard(sh2[a], sh2[b])
    est = estimate(sigs[a], sigs[b])
    next if exact < 0.2 && est < 0.2
    flag = exact >= 0.5 ? " DUP" : ""
    puts format("%s-%s  %5.3f  %5.3f%s", a, b, exact, est, flag)
    union(parent, a, b) if exact >= 0.5
  end
end

clusters = {}
names.each do |n|
  root = find(parent, n)
  (clusters[root] ||= []) << n
end
groups = clusters.values.select { |g| g.size > 1 }
puts "duplicate clusters: #{groups.size}"
groups.each { |g| puts "  #{g.join(", ")}" }
singles = clusters.values.select { |g| g.size == 1 }
puts "unique documents: #{singles.map(&:first).join(", ")}"

words_a = docs["a"].split(" ").to_set
words_h = docs["h"].split(" ").to_set
puts format("a/h word jaccard %.3f vs shingle jaccard %.3f", jaccard(words_a, words_h), jaccard(sh2["a"], sh2["h"]))

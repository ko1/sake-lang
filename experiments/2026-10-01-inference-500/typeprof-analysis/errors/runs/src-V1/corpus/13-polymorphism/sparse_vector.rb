require "set"

class SparseVec
  attr_reader :entries

  def initialize(entries)
    @entries = entries
  end

  def self.empty = SparseVec.new({})

  def [](k) = @entries.fetch(k, 0)

  def []=(k, x)
    if x == 0
      @entries.delete(k)
    else
      @entries[k] = x
    end
  end

  def keys = @entries.keys
  def nnz = @entries.size

  def +(b)
    out = SparseVec.new(@entries.dup)
    b.entries.each { |k, x| out[k] += x }
    out
  end

  def -(b)
    out = SparseVec.new(@entries.dup)
    b.entries.each { |k, x| out[k] -= x }
    out
  end

  def *(s)
    out = SparseVec.empty
    @entries.each { |k, x| out[k] = x * s }
    out
  end

  def dot(b)
    small, big = nnz <= b.nnz ? [self, b] : [b, self]
    small.entries.sum { |k, x| x * big[k] }
  end

  def norm = Math.sqrt(dot(self))

  def cosine(b)
    d = norm * b.norm
    d == 0 ? 0.0 : dot(b) / d
  end

  def top(n) = @entries.sort_by { |k, x| [-x, k] }.take(n)

  def to_s
    parts = keys.sort.map { |k| "#{k}:#{self[k]}" }
    "{#{parts.join(", ")}}"
  end
end

STOPWORDS = Set["the", "a", "and", "of", "to", "in", "is", "on", "for", "with"]

def term_vector(text)
  v = SparseVec.empty
  words = text.downcase.scan(/[a-z]+/)
  words.each do |w|
    next if STOPWORDS.include?(w)
    v[w] += 1
  end
  v
end

docs = [
  ["ruby", "Ruby is a dynamic language with a focus on simplicity and productivity"],
  ["python", "Python is a dynamic language with a focus on readability"],
  ["types", "Static types catch errors early; types document the program for the reader"],
  ["sake", "Sake writes types on operations; the program stays dynamic and simple in Ruby syntax"],
  ["bread", "Knead the dough, let it rise, and bake the bread in a hot oven"],
  ["pizza", "Pizza dough must rise slowly; bake it in a very hot oven"]
]

vectors = {}
docs.each { |name, text| vectors[name] = term_vector(text) }

vectors.each do |name, v|
  tops = v.top(3).map { |k, x| "#{k}(#{x})" }
  puts format("%-7s nnz=%2d norm=%.3f top: %s", name, v.nnz, v.norm, tops.join(" "))
end

puts "== most similar pairs =="
names = vectors.keys
pairs = names.combination(2).map { |a, b| [a, b, vectors[a].cosine(vectors[b])] }
ranked = pairs.sort_by { |a, b, s| -s }
ranked.take(5).each { |a, b, s| puts format("%-7s ~ %-7s %.3f", a, b, s) }

puts "== query =="
queries = ["dynamic language simplicity", "hot oven dough", "types for the program", "quantum chromodynamics"]
queries.each do |q|
  qv = term_vector(q)
  best = names.max_by { |n| qv.cosine(vectors[n]) }
  score = best ? qv.cosine(vectors[best]) : 0.0
  if best && score > 0
    puts format("%-30s -> %s (%.3f)", q, best, score)
  else
    puts format("%-30s -> no match", q)
  end
end

puts "== arithmetic =="
a = term_vector("dough rise bake bake")
b = term_vector("bake oven dough")
puts "a = #{a}"
puts "b = #{b}"
puts "a + b = #{a + b}"
puts "a - b = #{a - b}"
puts "a * 3 = #{a * 3}"
puts "a . b = #{a.dot(b)}"
c = a - a
puts "a - a = #{c} (nnz #{c.nnz})"
puts "a[missing] = #{a["missing"]}"
centroid = vectors.values.reduce(SparseVec.empty) { |acc, v| acc + v }
puts "corpus top terms: #{centroid.top(4).map { |k, x| "#{k}=#{x}" }.join(", ")}"

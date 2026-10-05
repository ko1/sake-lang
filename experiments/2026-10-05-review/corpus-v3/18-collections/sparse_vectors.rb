# Sparse vectors backed by a Hash: arithmetic and indexing operators, dot products, cosine similarity.

class SparseVec
  attr_reader :entries

  def initialize(entries)
    @entries = entries
  end

  def [](k) = @entries.fetch(k, 0)

  def []=(k, x)
    if x == 0
      @entries.delete(k)
    else
      @entries[k] = x
    end
  end

  def +(other)
    out = SparseVec.new(@entries.dup)
    other.entries.each { |k, x| out[k] = out[k] + x }
    out
  end

  def -(other) = self + other.scale(-1)

  def *(k) = SparseVec.new(@entries.transform_values { |x| x * k })

  def scale(k) = SparseVec.new(@entries.transform_values { |x| x * k })

  def dot(other)
    small, big = @entries.size <= other.entries.size ? [self, other] : [other, self]
    small.entries.sum { |k, x| x * big[k] }
  end

  def norm = Math.sqrt(dot(self))
  def nnz = @entries.size
  def keys = @entries.keys.to_set

  def to_s
    "{" + @entries.sort_by { |k, x| k }.map { |k, x| "#{k}:#{x}" }.join(" ") + "}"
  end
end

def from_text(text)
  v = SparseVec.new({})
  text.downcase.scan(/[a-z]+/).each { |w| v[w] += 1 }
  v
end

def cosine(a, b)
  na = a.norm
  nb = b.norm
  return 0.0 if na == 0.0 || nb == 0.0
  a.dot(b) / (na * nb)
end

a = SparseVec.new({"x" => 3, "y" => 4})
b = SparseVec.new({"y" => 1, "z" => 2})
puts "a = #{a}"
puts "b = #{b}"
puts "a + b = #{a + b}"
puts "a - b = #{a - b}"
puts "a * 2 = #{a * 2}"
puts "a . b = #{a.dot(b)}"
puts "|a| = #{a.norm}"
c = a - a
puts "a - a = #{c} (nnz #{c.nnz})"
a["w"] = 7
a["x"] = 0
puts "after edits a = #{a}, a[q] = #{a["q"]}"

docs = {
  "d1" => "the quick brown fox jumps over the lazy dog",
  "d2" => "the lazy dog sleeps all day",
  "d3" => "quick brown foxes are quick",
  "d4" => "a day in the life of a dog"
}
vecs = docs.transform_values { |t| from_text(t) }
puts "vocabulary sizes: #{vecs.map { |n, v| "#{n}=#{v.nnz}" }.join(" ")}"
total = vecs.values.reduce(SparseVec.new({})) { |acc, v| acc + v }
top = total.entries.sort_by { |w, n| [-n, w] }.take(4)
puts "most frequent: #{top.map { |w, n| "#{w}(#{n})" }.join(" ")}"

puts "cosine similarity:"
names = vecs.keys
names.each do |r|
  row = names.map { |c2| format("%.2f", cosine(vecs[r], vecs[c2])) }
  puts "  #{r} #{row.join(" ")}"
end
pairs = names.combination(2).map { |x, y| [x, y, cosine(vecs[x], vecs[y])] }
best = pairs.max_by { |x, y, s| s }
puts "closest pair: #{best[0]} & #{best[1]}"
others = vecs.reject { |n, v| n == "d3" }.values
shared = others.map(&:keys).reduce(:&)
puts "words in every doc but d3: #{shared.sort.join(" ")}"
query = from_text("lazy dog day")
ranked = names.sort_by { |n| 1.0 - cosine(query, vecs[n]) }
puts "query 'lazy dog day': #{ranked.join(" > ")}"

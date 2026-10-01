# A Bloom filter over 32-bit words using FNV-1a and djb2 with double hashing,
# measuring the false-positive rate against the theoretical estimate.

def fnv1a(s)
  s.bytes.reduce(0x811C9DC5) { |h, b| ((h ^ b) * 0x01000193) & 0xFFFFFFFF }
end

def djb2(s)
  s.bytes.reduce(5381) { |h, b| ((h << 5) + h + b) & 0xFFFFFFFF }
end

def popcount(n)
  c = 0
  while n != 0
    n &= n - 1
    c += 1
  end
  c
end

class Bloom
  attr_reader :size, :hashes, :words, :count

  def initialize(size, hashes, words, count)
    @size = size
    @hashes = hashes
    @words = words
    @count = count
  end

  def self.create(size, hashes) = new(size, hashes, Array.new((size + 31) / 32, 0), 0)

  def positions(item)
    h1 = fnv1a(item)
    h2 = djb2(item) | 1
    (0...@hashes).map { |i| (h1 + i * h2) % @size }
  end

  def add(item)
    positions(item).each { |p| @words[p / 32] |= 1 << (p % 32) }
    @count += 1
  end

  def include?(item)
    positions(item).all? { |p| (@words[p / 32] >> (p % 32)) & 1 == 1 }
  end

  def bits_set = @words.sum { |w| popcount(w) }

  def expected_fp = (1.0 - Math.exp(-@hashes * @count / @size.to_f)) ** @hashes
end

def word_list(prefix, n) = (1..n).map { |i| "#{prefix}-#{i * 7919 % 10007}" }

puts format("fnv1a(\"\") = %08x", fnv1a(""))
puts format("fnv1a(\"a\") = %08x", fnv1a("a"))
puts format("fnv1a(\"foobar\") = %08x", fnv1a("foobar"))
puts format("djb2(\"hello\") = %d", djb2("hello"))

members = word_list("user", 60)
strangers = word_list("guest", 150)

[[256, 2], [512, 3], [1024, 5]].each do |size, k|
  bf = Bloom.create(size, k)
  members.each { |m| bf.add(m) }
  missed = members.count { |m| !bf.include?(m) }
  fps = strangers.count { |s| bf.include?(s) }
  rate = fps.fdiv(strangers.size)
  fill = bf.bits_set.fdiv(size)
  puts format("m=%4d k=%d fill=%.2f false-negatives=%d false-positives=%3d/%d (%.3f, expected %.3f)",
              size, k, fill, missed, fps, strangers.size, rate, bf.expected_fp)
end

bf = Bloom.create(128, 3)
["apple", "banana", "cherry"].each { |w| bf.add(w) }
["apple", "banana", "durian", "elderberry", "cherry"].each do |w|
  puts "#{w}: #{bf.include?(w) ? "maybe present" : "definitely absent"}  #{bf.positions(w).inspect}"
end

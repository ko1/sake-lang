# MurmurHash3 (x86, 32-bit) implemented with explicit 32-bit masking, checked against
# known vectors, then used for a consistent-hashing ring with virtual nodes.

MASK32 = 0xFFFFFFFF

def rotl32(x, r) = ((x << r) | (x >> (32 - r))) & MASK32

def mul32(a, b) = (a * b) & MASK32

def fmix32(h)
  h ^= h >> 16
  h = mul32(h, 0x85EBCA6B)
  h ^= h >> 13
  h = mul32(h, 0xC2B2AE35)
  h ^ (h >> 16)
end

def murmur3(bytes, seed)
  c1 = 0xCC9E2D51
  c2 = 0x1B873593
  h = seed & MASK32
  n = bytes.size
  blocks = n / 4
  blocks.times do |i|
    j = i * 4
    k = bytes[j] | (bytes[j + 1] << 8) | (bytes[j + 2] << 16) | (bytes[j + 3] << 24)
    k = mul32(rotl32(mul32(k, c1), 15), c2)
    h ^= k
    h = (mul32(rotl32(h, 13), 5) + 0xE6546B64) & MASK32
  end
  tail = blocks * 4
  k = 0
  rest = n & 3
  k ^= bytes[tail + 2] << 16 if rest >= 3
  k ^= bytes[tail + 1] << 8 if rest >= 2
  if rest >= 1
    k ^= bytes[tail]
    k = mul32(rotl32(mul32(k, c1), 15), c2)
    h ^= k
  end
  fmix32(h ^ n)
end

def hash_str(s) = murmur3(s.bytes, 0)

class Ring
  attr_reader :points, :owners

  def initialize(points, owners)
    @points = points
    @owners = owners
  end

  def self.build(nodes, replicas)
    owners = {}
    nodes.each do |node|
      replicas.times { |r| owners[hash_str("#{node}##{r}")] = node }
    end
    new(owners.keys.sort, owners)
  end

  def lookup(key)
    h = hash_str(key)
    point = @points.bsearch { |p| p >= h } || @points.first
    @owners[point]
  end
end

puts "== test vectors =="
vectors = [["", 0, 0x00000000], ["", 1, 0x514E28B7], ["", 0xFFFFFFFF, 0x81F16F39],
           ["a", 0x9747B28C, 0x7FA09EA6], ["abc", 0, 0xB3DD93FA], ["Hello, world!", 0x9747B28C, 0x24884CBA],
           ["The quick brown fox jumps over the lazy dog", 0x9747B28C, 0x2FA826CD]]
vectors.each do |text, seed, want|
  got = murmur3(text.bytes, seed)
  puts format("%-45s seed=%08x %08x %s", text.inspect, seed, got, got == want ? "ok" : "MISMATCH want #{format("%08x", want)}")
end

puts "== ring =="
nodes = ["cache-a", "cache-b", "cache-c"]
keys = (1..120).map { |i| "session:#{i}" }
ring = Ring.build(nodes, 16)
before = keys.to_h { |k| [k, ring.lookup(k)] }
load = before.values.tally
nodes.each { |n| puts format("  %-8s %3d keys", n, load.fetch(n, 0)) }

bigger = Ring.build(["cache-a", "cache-b", "cache-c", "cache-d"], 16)
moved = keys.count { |k| bigger.lookup(k) != before[k] }
to_new = keys.count { |k| bigger.lookup(k) == "cache-d" }
puts "adding cache-d moved #{moved} of #{keys.size} keys (#{to_new} now on cache-d)"
only_to_new = keys.all? { |k| bigger.lookup(k) == before[k] || bigger.lookup(k) == "cache-d" }
puts "every moved key went to the new node: #{only_to_new}"

naive_moved = keys.count { |k| hash_str(k) % 3 != hash_str(k) % 4 }
puts "modulo hashing would have moved #{naive_moved}"

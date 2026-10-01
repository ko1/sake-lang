# A fixed-width bit set stored in one Integer, with indexing and the set operators,
# plus classic bit tricks: popcount, bit reversal, Gray code, and power-of-two rounding.

class BitSet
  attr_reader :width, :bits

  def initialize(width, bits)
    @width = width
    @bits = bits
  end

  def self.full_mask(width) = (1 << width) - 1

  def self.from_list(width, list)
    s = new(width, 0)
    list.each { |i| s[i] = true }
    s
  end

  def [](i)
    raise IndexError, "bit #{i} outside width #{@width}" if i < 0 || i >= @width
    (@bits >> i) & 1 == 1
  end

  def []=(i, v)
    raise IndexError, "bit #{i} outside width #{@width}" if i < 0 || i >= @width
    @bits = v ? @bits | (1 << i) : @bits & (BitSet.full_mask(@width) ^ (1 << i))
  end

  def &(other) = BitSet.new(@width, @bits & other.bits)
  def |(other) = BitSet.new(@width, @bits | other.bits)
  def ^(other) = BitSet.new(@width, @bits ^ other.bits)

  def complement = BitSet.new(@width, @bits ^ BitSet.full_mask(@width))
  def count = popcount(@bits)
  def members = (0...@width).select { |i| self[i] }
  def to_s = format("%b", @bits).rjust(@width, "0")
end

def popcount(n)
  c = 0
  while n != 0
    n &= n - 1
    c += 1
  end
  c
end

def reverse_bits(n, width)
  r = 0
  width.times do
    r = (r << 1) | (n & 1)
    n >>= 1
  end
  r
end

def gray(n) = n ^ (n >> 1)

def gray_decode(g)
  n = g
  shift = g >> 1
  while shift != 0
    n ^= shift
    shift >>= 1
  end
  n
end

def next_pow2(n)
  return 1 if n <= 1
  v = n - 1
  [1, 2, 4, 8, 16, 32].each { |s| v |= v >> s }
  v + 1
end

def lowest_set(n) = n & -n

puts "== bit tricks =="
[0, 1, 6, 255, 1023, 0xDEADBEEF].each do |n|
  puts format("%10d popcount=%2d lowest=%d next_pow2=%d", n, popcount(n), lowest_set(n), next_pow2(n))
end
puts format("reverse 0b00010110 (8) = %08b", reverse_bits(0b00010110, 8))
puts format("reverse 0x1 (32) = %08x", reverse_bits(1, 32))

puts "== gray code =="
codes = (0..7).map { |i| gray(i) }
puts codes.map { |g| format("%03b", g) }.join(" ")
adjacent = (1..7).all? { |i| popcount(codes[i] ^ codes[i - 1]) == 1 }
puts "neighbours differ in one bit: #{adjacent}"
puts "decoded: #{codes.map { |g| gray_decode(g) }.join(",")}"

puts "== bit sets =="
primes = BitSet.from_list(16, [2, 3, 5, 7, 11, 13])
odds = BitSet.from_list(16, (0...16).select(&:odd?))
puts "primes     #{primes}  #{primes.members.join(",")}"
puts "odds       #{odds}"
puts "both       #{primes & odds}"
puts "either     #{primes | odds}"
puts "exactly 1  #{primes ^ odds}"
puts "not prime  #{primes.complement} count=#{primes.complement.count}"
primes[2] = false
primes[15] = true
puts "edited     #{primes} has 15? #{primes[15]} has 2? #{primes[2]}"
begin
  primes[16] = true
rescue IndexError => e
  puts "error: #{e.message}"
end

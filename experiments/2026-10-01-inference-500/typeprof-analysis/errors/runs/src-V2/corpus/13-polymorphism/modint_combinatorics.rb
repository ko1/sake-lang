class ModulusMismatch < StandardError
  attr_reader :a, :b
  def initialize(message, a, b)
    super(message)
    @a = a
    @b = b
  end
end

class NotInvertible < StandardError
  attr_reader :value
  def initialize(message, value)
    super(message)
    @value = value
  end
end

class ModInt
  attr_reader :v, :m

  def initialize(v, m)
    @v = v
    @m = m
  end

  def self.of(v, m) = ModInt.new(v % m, m)

  def other(b)
    case b
    in Integer then ModInt.of(b, @m)
    in ModInt
      raise ModulusMismatch.new("mod #{@m} vs mod #{b.m}", @m, b.m) if b.m != @m
      b
    end
  end

  def +(b) = ModInt.of(@v + other(b).v, @m)
  def -(b) = ModInt.of(@v - other(b).v, @m)
  def *(b) = ModInt.of(@v * other(b).v, @m)
  def **(e) = ModInt.new(@v.pow(e, @m), @m)

  def inverse
    g = @v.gcd(@m)
    raise NotInvertible.new("#{@v} has no inverse mod #{@m}", @v) if g != 1
    # extended Euclid
    old_r, r = @v, @m
    old_s, s = 1, 0
    while r != 0
      q = old_r / r
      old_r, r = r, old_r - q * r
      old_s, s = s, old_s - q * s
    end
    ModInt.of(old_s, @m)
  end

  def /(b) = self * other(b).inverse
  def to_s = "#{@v} (mod #{@m})"
end

PRIME = 1_000_000_007

def factorials(n, m)
  facts = [ModInt.of(1, m)]
  (1..n).each { |i| facts << facts[i - 1] * i }
  facts
end

def binom(facts, n, k)
  return ModInt.of(0, facts[0].m) if k < 0 || k > n
  facts[n] / (facts[k] * facts[n - k])
end

def lucas(n, k, p)
  facts = factorials(p - 1, p)
  result = ModInt.of(1, p)
  while n > 0 || k > 0
    result *= binom(facts, n % p, k % p)
    n /= p
    k /= p
  end
  result
end

def rolling_hash(s, base, m)
  s.bytes.reduce(ModInt.of(0, m)) { |h, b| h * base + b }
end

def crt(residues)
  x = 0
  modulus = 1
  residues.each do |r|
    # find t with x + modulus * t == r.v (mod r.m)
    t = ModInt.of(r.v - x, r.m) / ModInt.of(modulus, r.m)
    x += modulus * t.v
    modulus *= r.m
  end
  ModInt.of(x, modulus)
end

facts = factorials(1000, PRIME)
puts "C(10, 3) = #{binom(facts, 10, 3)}"
puts "C(1000, 500) = #{binom(facts, 1000, 500)}"
puts "C(5, 7) = #{binom(facts, 5, 7)}"
row = (0..10).map { |k| binom(facts, 10, k).v }
puts "row 10: #{row.join(" ")}"
puts "catalan(1..10): #{(1..10).map { |n| (binom(facts, 2 * n, n) / (n + 1)).v }.join(" ")}"

puts "== Lucas mod 13 =="
[[100, 30], [1000, 1], [2026, 1001], [13, 13]].each do |n, k|
  puts "C(#{n}, #{k}) mod 13 = #{lucas(n, k, 13).v}"
end
exact = (1..30).reduce(1) { |acc, i| acc * (100 - i + 1) / i }
puts "check C(100, 30) mod 13 exactly: #{exact % 13 == lucas(100, 30, 13).v} (C(100, 30) = #{exact})"

puts "== arithmetic mod 17 =="
a = ModInt.of(5, 17)
b = ModInt.of(13, 17)
puts "a + b = #{a + b}"
puts "a - b = #{a - b}"
puts "a * b = #{a * b}"
puts "a / b = #{a / b}  check: #{(a / b) * b}"
puts "a ** 16 = #{a ** 16} (Fermat)"
puts "a + 100 = #{a + 100}, a * -1 = #{a * -1}"
[ModInt.of(6, 9), ModInt.of(4, 9)].each do |x|
  begin
    puts "1 / #{x} = #{x.inverse}"
  rescue NotInvertible => e
    puts "error: #{e.message}"
  end
end
begin
  puts a + ModInt.of(1, 19)
rescue ModulusMismatch => e
  puts "error: #{e.message}"
end

puts "== CRT =="
system = [ModInt.of(2, 3), ModInt.of(3, 5), ModInt.of(2, 7)]
puts "x = #{system.join(", ")}  =>  #{crt(system)}"
puts "x = 1 (mod 4), 2 (mod 9), 3 (mod 25) => #{crt([ModInt.of(1, 4), ModInt.of(2, 9), ModInt.of(3, 25)])}"

puts "== rolling hash =="
words = ["listen", "silent", "enlist", "google", "listen"]
hashes = words.map { |w| rolling_hash(w, 131, PRIME).v }
words.each_with_index { |w, i| puts format("%-7s %10d", w, hashes[i]) }
dupes = words.uniq.select { |w| words.count(w) > 1 }
puts "repeated: #{dupes.join(", ")}; distinct hashes: #{hashes.uniq.size}"

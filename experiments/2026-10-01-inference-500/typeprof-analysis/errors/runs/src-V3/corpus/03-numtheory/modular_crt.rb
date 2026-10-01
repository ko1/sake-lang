# Modular arithmetic with a Mod type (operators + - * / **), modular inverses,
# and the Chinese Remainder Theorem for systems of congruences.

class NotInvertible < StandardError
  attr_reader :value, :modulus

  def initialize(message, value, modulus)
    super(message)
    @value = value
    @modulus = modulus
  end
end

class ModulusMismatch < StandardError
end

class Mod
  include Comparable
  attr_reader :v, :m

  def initialize(v, m)
    @v = v
    @m = m
  end

  def self.make(v, m) = new(v % m, m)

  def check(b)
    raise ModulusMismatch, "moduli #{@m} and #{b.m} differ" if @m != b.m
  end

  def +(b)
    check(b)
    Mod.make(@v + b.v, @m)
  end

  def -(b)
    check(b)
    Mod.make(@v - b.v, @m)
  end

  def *(b)
    check(b)
    Mod.make(@v * b.v, @m)
  end

  def /(b) = self * b.inverse

  def **(e) = Mod.new(@v.pow(e, @m), @m)

  def <=>(b) = @v <=> b.v

  def inverse
    old_r, r = @v, @m
    old_s, s = 1, 0
    while r != 0
      q = old_r / r
      old_r, r = r, old_r - q * r
      old_s, s = s, old_s - q * s
    end
    raise NotInvertible.new("#{@v} has no inverse mod #{@m}", @v, @m) if old_r != 1
    Mod.make(old_s, @m)
  end

  def to_s = "#{@v} (mod #{@m})"
end

# x = r_i (mod m_i) for each [r, m]; moduli need not be coprime
def crt(congruences)
  x = 0
  m = 1
  congruences.each do |r, mi|
    g = m.gcd(mi)
    return nil if (r - x) % g != 0
    lcm = m / g * mi
    step = Mod.make(m / g, mi / g).inverse
    t = ((r - x) / g * step.v) % (mi / g)
    x = (x + m * t) % lcm
    m = lcm
  end
  [x, m]
end

a = Mod.make(17, 23)
b = Mod.make(9, 23)
puts "a = #{a}, b = #{b}"
puts "a + b = #{a + b}"
puts "a - b = #{a - b}"
puts "a * b = #{a * b}"
puts "a / b = #{a / b}"
puts "a ** 22 = #{a**22}"
puts "(a / b) * b == a: #{(a / b) * b == a}"
puts "a > b: #{a > b}"

puts "inverses mod 26:"
(1..12).each do |k|
  inv = Mod.make(k, 26).inverse
  puts "  #{k} -> #{inv.v}"
rescue NotInvertible => e
  puts "  #{k} -> none (gcd #{e.value.gcd(e.modulus)})"
end

begin
  puts Mod.make(3, 7) + Mod.make(3, 11)
rescue ModulusMismatch => e
  puts "error: #{e.message}"
end

residues = (0..10).map { |k| Mod.make(k * k, 11) }
qr = residues.sort.map(&:v).uniq
puts "quadratic residues mod 11: #{qr}"
puts "largest: #{residues.max}"

systems = [
  [[2, 3], [3, 5], [2, 7]],
  [[1, 4], [3, 6]],
  [[1, 4], [2, 6]],
  [[0, 7], [3, 11], [9, 13], [1, 2]]
]
puts "CRT:"
systems.each do |sys|
  desc = sys.map { |r, m| "x=#{r} (#{m})" }.join(", ")
  if (res = crt(sys))
    x, m = res
    ok = sys.all? { |r, mi| x % mi == r % mi }
    puts "  #{desc} => x = #{x} mod #{m} #{ok ? "ok" : "WRONG"}"
  else
    puts "  #{desc} => no solution"
  end
end

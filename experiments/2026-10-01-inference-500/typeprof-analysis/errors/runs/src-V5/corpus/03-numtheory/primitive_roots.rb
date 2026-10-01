# Multiplicative orders and primitive roots modulo n, index (discrete log) tables,
# and baby-step giant-step for discrete logarithms.

class NoPrimitiveRoot < StandardError
  attr_reader :n

  def initialize(message, n)
    super(message)
    @n = n
  end
end

def phi(n)
  result = n
  m = n
  p = 2
  while p * p <= m
    if m % p == 0
      m /= p while m % p == 0
      result -= result / p
    end
    p += 1
  end
  result -= result / m if m > 1
  result
end

def prime_factors(n)
  fs = []
  p = 2
  while p * p <= n
    if n % p == 0
      fs << p
      n /= p while n % p == 0
    end
    p += 1
  end
  fs << n if n > 1
  fs
end

def order(a, n)
  return nil if a.gcd(n) != 1
  k = 1
  x = a % n
  while x != 1 % n
    x = x * a % n
    k += 1
  end
  k
end

def primitive_root(n)
  t = phi(n)
  fs = prime_factors(t)
  g = (1..(n - 1)).find do |c|
    c.gcd(n) == 1 && fs.all? { |q| c.pow(t / q, n) != 1 }
  end
  raise NoPrimitiveRoot.new("no primitive root modulo #{n}", n) unless g
  g
end

def all_primitive_roots(n)
  g = primitive_root(n)
  t = phi(n)
  (1..t).select { |k| k.gcd(t) == 1 }.map { |k| g.pow(k, n) }.sort
end

# smallest x >= 0 with g^x = h (mod p), or nil
def bsgs(g, h, p)
  m = Integer.sqrt(p - 1) + 1
  table = {}
  e = 1
  m.times do |j|
    table[e] ||= j
    e = e * g % p
  end
  factor = g.pow(p - 1 - m, p)
  gamma = h % p
  m.times do |i|
    j = table[gamma]
    return i * m + j if j
    gamma = gamma * factor % p
  end
  nil
end

puts "orders modulo 13:"
(1..12).each { |a| print format("%3d", order(a, 13)) }
puts

puts "primitive roots:"
[7, 9, 10, 12, 18, 23, 25, 41, 50].each do |n|
  roots = all_primitive_roots(n)
  shown = roots.size > 8 ? "#{roots.take(8).join(" ")} ..." : roots.join(" ")
  puts format("  n=%-3d phi=%-3d count=%-3d %s", n, phi(n), roots.size, shown)
rescue NoPrimitiveRoot => e
  puts format("  n=%-3d %s", e.n, e.message)
end

p = 31
g = primitive_root(p)
index = {}
(0..(p - 2)).each { |k| index[g.pow(k, p)] = k }
puts "index table mod #{p} (base #{g}):"
(1..(p - 1)).each_slice(10) do |row|
  puts "  " + row.map { |a| format("%2d:%-2d", a, index[a]) }.join(" ")
end
# x^5 = 5 mod 31  <=>  5*ind(x) = ind(5) mod 30
sols = (1..(p - 1)).select { |x| (5 * index[x] - index[5]) % (p - 1) == 0 }
puts "solutions of x^5 = 5 (mod 31): #{sols}"
puts "check: #{sols.map { |x| x.pow(5, p) }}"

puts "baby-step giant-step:"
[[2, 1, 1019], [5, 1234, 10007], [3, 13, 17], [2, 3, 7], [6, 1, 1000003], [2, 999, 1000003]].each do |b, h, q|
  if (x = bsgs(b, h, q)) && x
    puts "  #{b}^x = #{h} (mod #{q}): x = #{x}  check #{b.pow(x, q)}"
  else
    puts "  #{b}^x = #{h} (mod #{q}): no solution"
  end
end

artin = (3..200).select { |q| (2..Integer.sqrt(q)).none? { |d| q % d == 0 } }
with2 = artin.select { |q| order(2, q) == q - 1 }
puts "primes < 200 with 2 as a primitive root: #{with2.size}/#{artin.size}"
puts "  #{with2.join(" ")}"

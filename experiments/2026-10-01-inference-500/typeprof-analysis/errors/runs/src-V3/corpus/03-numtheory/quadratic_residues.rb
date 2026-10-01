# Quadratic residues: Legendre and Jacobi symbols, quadratic reciprocity check,
# Tonelli-Shanks square roots mod p, and primes as sums of two squares.

class NoSquareRoot < StandardError
  attr_reader :a, :p

  def initialize(message, a, p)
    super(message)
    @a = a
    @p = p
  end
end

def legendre(a, p)
  r = (a % p).pow((p - 1) / 2, p)
  r == p - 1 ? -1 : r
end

def jacobi(a, n)
  raise ArgumentError, "n must be odd and positive" if n <= 0 || n.even?
  a %= n
  result = 1
  while a != 0
    while a.even?
      a /= 2
      result = -result if n % 8 == 3 || n % 8 == 5
    end
    a, n = n, a
    result = -result if a % 4 == 3 && n % 4 == 3
    a %= n
  end
  n == 1 ? result : 0
end

def sqrt_mod(a, p)
  a %= p
  return 0 if a == 0
  raise NoSquareRoot.new("#{a} is not a square mod #{p}", a, p) if legendre(a, p) != 1
  return a.pow((p + 1) / 4, p) if p % 4 == 3
  q = p - 1
  s = 0
  while q.even?
    q /= 2
    s += 1
  end
  z = 2
  z += 1 while legendre(z, p) != -1
  m = s
  c = z.pow(q, p)
  t = a.pow(q, p)
  r = a.pow((q + 1) / 2, p)
  while t != 1
    i = 0
    t2 = t
    while t2 != 1
      t2 = t2 * t2 % p
      i += 1
    end
    b = c.pow(2**(m - i - 1), p)
    m = i
    c = b * b % p
    t = t * c % p
    r = r * b % p
  end
  r
end

def two_squares(p)
  return [1, 1] if p == 2
  x = sqrt_mod(p - 1, p)
  a, b = p, x
  limit = Integer.sqrt(p)
  a, b = b, a % b while b > limit
  c = Integer.sqrt(p - b * b)
  [b, c].minmax
end

def primes_upto(n) = (2..n).select { |k| (2..Integer.sqrt(k)).none? { |d| k % d == 0 } }

p = 23
qr = (1..(p - 1)).select { |a| legendre(a, p) == 1 }
puts "quadratic residues mod #{p}: #{qr.join(" ")}"
squares = (1..(p - 1)).map { |x| x * x % p }.sort.uniq
puts "matches squares: #{squares == qr}"

primes = primes_upto(200).drop(1)
recip = []
primes.each do |p1|
  primes.each do |q1|
    next if q1 <= p1
    lhs = legendre(p1, q1) * legendre(q1, p1)
    rhs = ((p1 - 1) / 2 * ((q1 - 1) / 2)).even? ? 1 : -1
    recip << [p1, q1] if lhs != rhs
  end
end
puts "reciprocity violations among odd primes < 200: #{recip.size}"

puts "Jacobi symbols (a/n):"
[15, 21, 45].each do |n|
  row = (1..12).map { |a| jacobi(a, n).to_s.rjust(2) }
  puts "  n=#{n}: #{row.join(" ")}"
end
begin
  jacobi(3, 10)
rescue ArgumentError => e
  puts "  jacobi(3, 10): #{e.message}"
end

puts "square roots mod p:"
[[10, 13], [5, 41], [2, 113], [3, 7], [56, 101], [1030, 10009]].each do |a, pr|
  r = sqrt_mod(a, pr)
  lo = [r, (pr - r) % pr].min
  puts "  sqrt(#{a}) mod #{pr} = #{lo}, #{pr - lo}  (check #{lo * lo % pr})"
rescue NoSquareRoot => e
  puts "  #{e.message}"
end

puts "primes = 1 mod 4 as a^2 + b^2:"
sums = primes.select { |q| q % 4 == 1 && q < 120 }.map do |q|
  a, b = two_squares(q)
  "#{q}=#{a}^2+#{b}^2"
end
sums.each_slice(5) { |row| puts "  " + row.join("  ") }

counts = Hash.new(0)
primes.each { |q| counts[legendre(2, q)] += 1 }
puts "2 is a residue for #{counts[1]} primes, a non-residue for #{counts[-1]}"

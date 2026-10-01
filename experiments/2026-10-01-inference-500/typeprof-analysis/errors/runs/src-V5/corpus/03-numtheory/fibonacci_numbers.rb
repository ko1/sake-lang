# Fibonacci numbers: 2x2 matrix powers with a Mat2 type, fast doubling,
# Pisano periods, Zeckendorf representations, and divisibility identities.

class Mat2
  attr_reader :a, :b, :c, :d

  def initialize(a, b, c, d)
    @a = a
    @b = b
    @c = c
    @d = d
  end

  def *(y)
    Mat2.new(@a * y.a + @b * y.c, @a * y.b + @b * y.d,
             @c * y.a + @d * y.c, @c * y.b + @d * y.d)
  end

  def %(m) = Mat2.new(@a % m, @b % m, @c % m, @d % m)

  def self.identity = Mat2.new(1, 0, 0, 1)

  def power(n, m)
    result = Mat2.identity
    base = self
    while n > 0
      result = result * base % m if n.odd?
      base = base * base % m
      n /= 2
    end
    result
  end

  def to_s = "[[#{@a}, #{@b}], [#{@c}, #{@d}]]"
end

def fib_matrix(n, m) = Mat2.new(1, 1, 1, 0).power(n, m).b

# returns [F(n), F(n+1)]
def fib_pair(n)
  return [0, 1] if n == 0
  a, b = fib_pair(n / 2)
  c = a * (2 * b - a)
  d = a * a + b * b
  n.even? ? [c, d] : [d, c + d]
end

def fib(n) = fib_pair(n).first

def pisano(m)
  return 1 if m == 1
  a, b = 0, 1
  k = 0
  loop do
    a, b = b, (a + b) % m
    k += 1
    return k if a == 0 && b == 1
  end
end

def zeckendorf(n)
  fibs = [1, 2]
  fibs << fibs[-1] + fibs[-2] while fibs.last <= n
  parts = []
  fibs.reverse_each do |f|
    if f <= n
      parts << f
      n -= f
    end
  end
  parts
end

puts "F(0..20): #{(0..20).map { |n| fib(n) }.join(" ")}"
puts "F(100) = #{fib(100)}"
puts "F(300) has #{fib(300).to_s.length} digits"
m = Mat2.new(1, 1, 1, 0)
puts "M^10 = #{m.power(10, 1_000_000_007)}"

agree = (0..200).all? { |n| fib_matrix(n, 1_000_000_007) == fib(n) % 1_000_000_007 }
puts "matrix and doubling agree for n <= 200: #{agree}"
puts "F(10^15) mod 1e9+7 = #{fib_matrix(10**15, 1_000_000_007)}"

puts "Pisano periods:"
periods = (1..30).map { |k| pisano(k) }
(1..30).each_slice(10) do |row|
  puts "  " + row.map { |k| format("%2d:%-3d", k, periods[k - 1]) }.join(" ")
end
puts "  pi(10) = 60, so last digits repeat every 60: #{fib(7) % 10 == fib(67) % 10}"

puts "Zeckendorf representations:"
[10, 64, 100, 1000, 12345].each do |n|
  puts "  #{n} = #{zeckendorf(n).join(" + ")}"
end
ok = (1..150).all? do |n|
  parts = zeckendorf(n)
  idx = parts.map { |f| (2..30).find { |i| fib(i) == f } }
  parts.sum == n && idx.each_cons(2).all? { |x, y| x - y >= 2 }
end
puts "  1..150 all valid and non-consecutive: #{ok}"

puts "identities:"
gcd_ok = (1..25).all? { |i| (1..25).all? { |j| fib(i).gcd(fib(j)) == fib(i.gcd(j)) } }
puts "  gcd(F(m), F(n)) = F(gcd(m, n)) for m, n <= 25: #{gcd_ok}"
cassini = (1..60).all? { |n| fib(n - 1) * fib(n + 1) - fib(n)**2 == (n.even? ? 1 : -1) }
puts "  Cassini F(n-1)F(n+1) - F(n)^2 = (-1)^n for n <= 60: #{cassini}"
entry = (1..15).map { |k| (1..200).find { |n| (fib(n) % k).zero? } }
puts "  rank of apparition for k = 1..15: #{entry.join(" ")}"
ratio = Rational(fib(40), fib(39)).to_f
puts format("  F(40)/F(39) = %.12f, golden ratio = %.12f", ratio, (1 + Math.sqrt(5)) / 2)

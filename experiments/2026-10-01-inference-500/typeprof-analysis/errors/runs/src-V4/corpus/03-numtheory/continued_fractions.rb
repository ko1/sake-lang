# Continued fractions: expansions of rationals, periodic expansions of square
# roots, convergents as Rationals, and the fundamental solution of Pell's equation.

def cf_of_rational(r)
  terms = []
  num = r.numerator
  den = r.denominator
  while den != 0
    q, rem = num.divmod(den)
    terms << q
    num, den = den, rem
  end
  terms
end

def value_of(terms)
  acc = nil
  terms.reverse_each do |t|
    acc = !acc     ? Rational(t, 1) : t + 1 / acc
  end
  acc
end

# sqrt(n) = [a0; (a1, ..., ak)] ; returns nil for perfect squares
def sqrt_cf(n)
  a0 = Integer.sqrt(n)
  return nil if a0 * a0 == n
  m = 0
  d = 1
  a = a0
  period = []
  while a != 2 * a0
    m = d * a - m
    d = (n - m * m) / d
    a = (a0 + m) / d
    period << a
  end
  { a0: a0, period: period }
end

def convergents(a0, period, count)
  out = []
  h1, h0 = a0, 1
  k1, k0 = 1, 0
  out << Rational(h1, k1)
  i = 0
  while out.size < count
    a = period[i % period.size]
    h1, h0 = a * h1 + h0, h1
    k1, k0 = a * k1 + k0, k1
    out << Rational(h1, k1)
    i += 1
  end
  out
end

def pell(n)
  cf = sqrt_cf(n)
  return nil unless cf
  convergents(cf[:a0], cf[:period], 2 * cf[:period].size + 2).each do |c|
    x = c.numerator
    y = c.denominator
    return [x, y] if x * x - n * y * y == 1
  end
  nil
end

def show_cf(terms)
  "[#{terms.first}; #{terms.drop(1).join(", ")}]"
end

puts "rationals:"
[Rational(415, 93), Rational(649, 200), Rational(-17, 5), 3r / 7].each do |r|
  terms = cf_of_rational(r)
  back = value_of(terms)
  puts "  #{r} = #{show_cf(terms)}  (back: #{back})"
end

puts "square roots:"
lens = {}
(2..30).each do |n|
  cf = sqrt_cf(n)
  next unless cf
  lens[n] = cf[:period].size
  puts "  sqrt(#{n}) = [#{cf[:a0]}; (#{cf[:period].join(", ")})]" if n <= 14 || n == 29
end
odd = lens.keys.select { |n| lens[n].odd? }
puts "  odd periods for n <= 30: #{odd.join(" ")}"

puts "convergents of sqrt(2):"
convergents(1, [2], 8).each do |c|
  err = (c.to_f - Math.sqrt(2)).abs
  puts format("  %-10s %.10f  err %.2e", c.to_s, c.to_f, err)
end

puts "Pell x^2 - n*y^2 = 1:"
[2, 3, 5, 7, 13, 29, 61, 9].each do |n|
  if (sol = pell(n))
    x, y = sol
    puts "  n=#{n}: x=#{x}, y=#{y}"
  else
    puts "  n=#{n}: perfect square, only trivial solution"
  end
end

golden = convergents(1, [1], 12)
puts "golden ratio convergents: #{golden.map(&:to_s).join(" ")}"

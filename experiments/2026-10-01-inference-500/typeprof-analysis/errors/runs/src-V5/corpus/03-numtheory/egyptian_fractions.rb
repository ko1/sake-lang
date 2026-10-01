# Egyptian fractions: greedy (Fibonacci-Sylvester) and splitting expansions of
# Rationals into distinct unit fractions, harmonic numbers, and Erdos-Straus 4/n.

def greedy(r)
  units = []
  while r.numerator != 0
    d = r.denominator.ceildiv(r.numerator)
    units << d
    r -= Rational(1, d)
  end
  units
end

# replace duplicates 1/d + 1/d by 1/d + 1/(d+1) + 1/(d(d+1)) until all are distinct
def split_duplicates(units)
  counts = units.tally
  counts.default = 0
  while (dup = counts.keys.sort.find { |d| counts[d] > 1 }) && dup
    counts[dup] -= 1
    counts[dup + 1] += 1
    counts[dup * (dup + 1)] += 1
  end
  counts.keys.select { |d| counts[d] > 0 }.sort
end

def total(units) = units.sum(0r) { |d| Rational(1, d) }

def show(units) = units.map { |d| "1/#{d}" }.join(" + ")

# 4/n = 1/x + 1/y + 1/z with x <= y <= z, smallest x then y
def erdos_straus(n)
  target = Rational(4, n)
  (n.ceildiv(4)..(3 * n)).each do |x|
    r1 = target - Rational(1, x)
    next unless r1 > 0
    y_lo = [r1.denominator.ceildiv(r1.numerator), x].max
    y_hi = 2 * r1.denominator / r1.numerator
    (y_lo..y_hi).each do |y|
      r2 = r1 - Rational(1, y)
      return [x, y, r2.denominator] if r2 > 0 && r2.numerator == 1 && r2.denominator >= y
    end
  end
  nil
end

puts "greedy expansions:"
[Rational(4, 13), Rational(5, 121), Rational(7, 15), Rational(3, 7), Rational(13, 17)].each do |r|
  units = greedy(r)
  puts "  #{r} = #{show(units)}"
  raise "bad expansion of #{r}" if total(units) != r
end
big = greedy(Rational(5, 121))
puts "  largest denominator for 5/121 has #{big.max.to_s.length} digits"

puts "improper fractions via harmonic prefix + splitting:"
[Rational(3, 2), Rational(2, 1), Rational(9, 4)].each do |r|
  prefix = []
  rest = r
  d = 1
  while rest >= Rational(1, d)
    prefix << d
    rest -= Rational(1, d)
    d += 1
  end
  units = rest == 0 ? prefix : split_duplicates(prefix + greedy(rest))
  puts "  #{r} = #{show(units)} (#{units.size} terms, ok=#{total(units) == r})"
end

puts "splitting 2/n as duplicates:"
[3, 5, 7].each do |n|
  puts "  2/#{n} = #{show(split_duplicates([n, n]))}"
end

puts "harmonic numbers:"
h = 0r
(1..20).each do |n|
  h += Rational(1, n)
  puts format("  H(%2d) = %-28s ~ %.6f", n, h.to_s, h.to_f) if n % 5 == 0
end
n = 1
s = 0.0
while s < 5.0
  s += 1.0 / n
  n += 1
end
puts "  harmonic sum first exceeds 5 at n = #{n - 1}"

puts "Erdos-Straus 4/n = 1/x + 1/y + 1/z:"
fails = []
(2..60).each do |k|
  if (sol = erdos_straus(k)) && sol
    x, y, z = sol
    puts "  4/#{k} = 1/#{x} + 1/#{y} + 1/#{z}" if k % 10 == 3 || k == 2
  else
    fails << k
  end
end
puts "  no decomposition found for: #{fails.empty? ? "none" : fails.join(" ")}"

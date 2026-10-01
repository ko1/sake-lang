# Farey sequences and the Stern-Brocot tree: generating F_n, checking neighbour
# properties, paths to fractions, and best rational approximations.

def farey(n)
  a, b, c, d = 0, 1, 1, n
  seq = [Rational(a, b)]
  while c <= n
    k = (n + b) / d
    a, b, c, d = c, d, k * c - a, k * d - b
    seq << Rational(a, b)
  end
  seq
end

def neighbours_ok?(seq)
  seq.each_cons(2).all? { |x, y| y.numerator * x.denominator - x.numerator * y.denominator == 1 }
end

def mediant(x, y)
  Rational(x.numerator + y.numerator, x.denominator + y.denominator)
end

# path from 1/1 to the target in the Stern-Brocot tree, as L/R letters
def sb_path(target)
  lo = [0, 1]
  hi = [1, 0]
  path = +""
  200.times do
    m = Rational(lo[0] + hi[0], lo[1] + hi[1])
    return path if m == target
    if target < m
      path << "L"
      hi = [lo[0] + hi[0], lo[1] + hi[1]]
    else
      path << "R"
      lo = [lo[0] + hi[0], lo[1] + hi[1]]
    end
  end
  raise "path too long for #{target}"
end

def from_path(path)
  lo = [0, 1]
  hi = [1, 0]
  path.each_char do |c|
    med = [lo[0] + hi[0], lo[1] + hi[1]]
    if c == "L"
      hi = med
    else
      lo = med
    end
  end
  Rational(lo[0] + hi[0], lo[1] + hi[1])
end

# closest fraction to x with denominator <= max_den, by walking the tree
def best_approx(x, max_den)
  lo = [0, 1]
  hi = [1, 0]
  best = Rational(0, 1)
  loop do
    break if lo[1] + hi[1] > max_den
    m = Rational(lo[0] + hi[0], lo[1] + hi[1])
    best = m if (m.to_f - x).abs < (best.to_f - x).abs
    if x < m.to_f
      hi = [m.numerator, m.denominator]
    else
      lo = [m.numerator, m.denominator]
    end
  end
  best
end

(1..6).each do |n|
  puts "F#{n}: #{farey(n).map(&:to_s).join(" ")}"
end

puts "sizes |F_n| = 1 + sum phi(k):"
sizes = (1..12).map { |n| farey(n).size }
puts "  #{sizes.join(" ")}"
puts "neighbour determinant = 1 for F_1..F_12: #{(1..12).all? { |n| neighbours_ok?(farey(n)) }}"

f7 = farey(7)
idx = f7.index(Rational(3, 7))
left = f7[idx - 1]
right = f7[idx + 1]
puts "neighbours of 3/7 in F7: #{left} and #{right}, mediant #{mediant(left, right)}"

puts "Stern-Brocot paths:"
[Rational(3, 7), Rational(5, 2), Rational(13, 8), Rational(1, 1), Rational(22, 7)].each do |r|
  path = sb_path(r)
  shown = path.empty? ? "(root)" : path
  puts format("  %-6s %-12s back: %s", r.to_s, shown, from_path(path).to_s)
end

puts "best approximations of pi:"
[1, 7, 57, 106, 113, 1000, 33102].each do |den|
  r = best_approx(Math::PI, den)
  puts format("  den <= %-6d %-12s err %.3e", den, r.to_s, (r.to_f - Math::PI).abs)
end

puts "best approximations of sqrt(2) and e:"
[["sqrt2", Math.sqrt(2)], ["e", Math.exp(1)]].each do |name, x|
  rs = [10, 100, 1000].map { |d| best_approx(x, d).to_s }
  puts "  #{name}: #{rs.join(", ")}"
end

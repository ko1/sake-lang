class Summer
  attr_accessor :sum, :comp

  def initialize(sum = 0.0, comp = 0.0)
    @sum = sum
    @comp = comp
  end

  # Kahan-Babuska (Neumaier) compensated addition
  def add(x)
    t = @sum + x
    if @sum.abs >= x.abs
      @comp += (@sum - t) + x
    else
      @comp += (x - t) + @sum
    end
    @sum = t
    self
  end

  def total = @sum + @comp
end

def naive_sum(xs) = xs.reduce(0.0) { |acc, x| acc + x }

def kahan_sum(xs)
  s = Summer.new
  xs.each { |x| s.add(x) }
  s.total
end

def pairwise_sum(xs, lo, hi)
  return 0.0 if hi <= lo
  return xs[lo] if hi - lo == 1
  mid = (lo + hi) / 2
  pairwise_sum(xs, lo, mid) + pairwise_sum(xs, mid, hi)
end

def machine_epsilon
  eps = 1.0
  eps /= 2.0 while 1.0 + eps / 2.0 > 1.0
  eps
end

def quadratic_naive(a, b, c)
  d = Math.sqrt(b * b - 4.0 * a * c)
  [(-b + d) / (2.0 * a), (-b - d) / (2.0 * a)]
end

def quadratic_stable(a, b, c)
  d = Math.sqrt(b * b - 4.0 * a * c)
  q = b >= 0.0 ? -0.5 * (b + d) : -0.5 * (b - d)
  [c / q, q / a]
end

def ulps_between(a, b)
  return 0 if a == b
  lo, hi = [a, b].minmax
  count = 0
  while lo < hi && count < 1000
    lo = lo.next_float
    count += 1
  end
  count
end

eps = machine_epsilon
puts format("machine epsilon: %.6e (2^%d)", eps, Math.log2(eps).round)
puts format("1.0 + eps/2 == 1.0: %s", 1.0 + eps / 2.0 == 1.0)
puts format("0.1 + 0.2 = %.17f, ulps from 0.3: %d", 0.1 + 0.2, ulps_between(0.1 + 0.2, 0.3))

cases = [
  ["harmonic 1..3000", (1..3000).map { |k| 1.0 / k }],
  ["alternating 1-1/2+1/3...", (1..3000).map { |k| (k.odd? ? 1.0 : -1.0) / k }],
  ["big + many small", [1.0e16] + Array.new(2000, 1.0)],
  ["tenths x 2000", Array.new(2000, 0.1)]
]
puts format("%-26s %22s %22s %22s", "series", "naive", "kahan", "pairwise")
cases.each do |name, xs|
  n = naive_sum(xs)
  k = kahan_sum(xs)
  pw = pairwise_sum(xs, 0, xs.size)
  puts format("%-26s %22.15f %22.15f %22.15f", name, n, k, pw)
  sorted = xs.sort_by(&:abs)
  puts format("%-26s sorted ascending: %.15f (naive)", "", naive_sum(sorted))
end
puts format("ln 2 = %.15f", Math.log(2.0))

puts "quadratic x^2 + b x + 1 = 0, small root:"
[1.0e3, 1.0e5, 1.0e7, 1.0e9].each do |b|
  n1, _n2 = quadratic_naive(1.0, b, 1.0)
  s1, _s2 = quadratic_stable(1.0, b, 1.0)
  exact = -1.0 / b
  rel_n = ((n1 - exact) / exact).abs
  rel_s = ((s1 - exact) / exact).abs
  puts format("  b=%.0e naive=%.10e (rel err %.1e) stable=%.10e (rel err %.1e)", b, n1, rel_n, s1, rel_s)
end

puts "(1 + 1/n)^n vs e:"
[10, 1000, 100000, 10000000, 1000000000000000].each do |n|
  approx = (1.0 + 1.0 / n) ** n
  puts format("  n=%-17d %.12f err=%.2e", n, approx, (approx - Math::E).abs)
end

puts "special values:"
inf = Float::INFINITY
nan = inf - inf
puts "  inf=#{inf} -inf=#{-inf} nan=#{nan}"
puts "  nan == nan: #{nan == nan}, nan?: #{nan.nan?}, finite?(inf): #{inf.finite?}"
puts "  infinite?: #{inf.infinite?} #{(-inf).infinite?} #{1.0.infinite?.inspect}"
puts "  1/inf = #{1.0 / inf}, -1/inf = #{-1.0 / inf}"
begin
  nan.to_i
rescue FloatDomainError
  puts "  to_i(nan) raised FloatDomainError"
end

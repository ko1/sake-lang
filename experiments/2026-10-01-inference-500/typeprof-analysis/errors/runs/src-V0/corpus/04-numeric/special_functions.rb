class PoleError < StandardError
  attr_reader :at

  def initialize(message, at)
    super(message)
    @at = at
  end
end

LANCZOS = [0.99999999999980993, 676.5203681218851, -1259.1392167224028, 771.32342877765313,
           -176.61502916214059, 12.507343278686905, -0.13857109526572012,
           9.9843695780195716e-6, 1.5056327351493116e-7]

def gamma(x)
  raise PoleError.new("gamma has a pole", x) if x <= 0.0 && x.floor == x
  return Math::PI / (Math.sin(Math::PI * x) * gamma(1.0 - x)) if x < 0.5
  g = 7.0
  z = x - 1.0
  a = LANCZOS[0]
  t = z + g + 0.5
  (1...LANCZOS.size).each { |i| a += LANCZOS[i] / (z + i) }
  Math.sqrt(2.0 * Math::PI) * t ** (z + 0.5) * Math.exp(-t) * a
end

def log_gamma(x)
  # Stirling series for large x, recurrence below 10
  shift = 0.0
  while x < 10.0
    shift -= Math.log(x)
    x += 1.0
  end
  inv = 1.0 / x
  inv2 = inv * inv
  series = inv * (1.0 / 12.0 - inv2 * (1.0 / 360.0 - inv2 / 1260.0))
  shift + (x - 0.5) * Math.log(x) - x + 0.5 * Math.log(2.0 * Math::PI) + series
end

def erf_series(x)
  sum = 0.0
  term = x
  n = 0
  while term.abs > 1e-17 * sum.abs || n < 3
    sum += term / (2 * n + 1)
    n += 1
    term = -term * x * x / n
    break if n > 200
  end
  2.0 / Math.sqrt(Math::PI) * sum
end

def erfc_cf(x)
  # continued fraction x + (1/2)/(x + 1/(x + (3/2)/(x + ...))), evaluated from the tail
  t = x
  60.downto(1) { |k| t = x + (k / 2.0) / t }
  Math.exp(-x * x) / Math.sqrt(Math::PI) / t
end

def erf(x)
  return -erf(-x) if x < 0.0
  x < 2.5 ? erf_series(x) : 1.0 - erfc_cf(x)
end

def bessel_j0(x)
  sum = 0.0
  term = 1.0
  k = 0
  while term.abs > 1e-16 && k < 100
    sum += term
    k += 1
    term = -term * (x / 2.0) ** 2 / (k * k)
  end
  sum
end

def beta(a, b) = Math.exp(log_gamma(a) + log_gamma(b) - log_gamma(a + b))

def cached_gamma(cache, x)
  v = cache[x]
  return [v, true] if v
  v = gamma(x)
  cache[x] = v
  [v, false]
end

cache = {}

puts "gamma at integers vs factorial:"
fact = 1
(1..10).each do |n|
  g = gamma(n * 1.0)
  puts format("  gamma(%2d) = %14.4f  (%d!) rel err %.1e", n, g, n - 1, (g - fact).abs / fact)
  fact *= n
end
puts format("gamma(0.5)^2 = %.12f (pi = %.12f)", gamma(0.5) ** 2, Math::PI)
puts format("gamma(-1.5) = %.10f", gamma(-1.5))
[0.0, -2.0, 3.5].each do |x|
  puts format("gamma(%.1f) = %.10f", x, gamma(x))
rescue PoleError => e
  puts format("gamma(%.1f): %s at %.1f", x, e.message, e.at)
end

puts "log-gamma vs log(gamma):"
[0.7, 3.3, 12.0, 25.5].each do |x|
  puts format("  x=%5.1f lgamma=%.12f log(gamma)=%.12f", x, log_gamma(x), Math.log(gamma(x)))
end
puts format("lgamma(200) = %.6f (gamma would overflow: %s)", log_gamma(200.0), gamma(200.0).infinite? ? "yes" : "no")

puts "erf:"
[0.1, 0.5, 1.0, 2.0, 2.4, 2.6, 3.5, -1.0].each do |x|
  puts format("  erf(%4.1f) = %.15f", x, erf(x))
end
puts format("continuity at 2.5: series %.15f, cf %.15f", erf_series(2.5), 1.0 - erfc_cf(2.5))

puts "Bessel J0 zeros by bisection:"
zeros = []
prev_x = 0.0
prev_v = bessel_j0(0.0)
(1..120).each do |i|
  x = i * 0.1
  v = bessel_j0(x)
  if prev_v * v < 0.0
    lo = prev_x
    hi = x
    50.times do
      mid = (lo + hi) / 2.0
      if bessel_j0(lo) * bessel_j0(mid) <= 0.0
        hi = mid
      else
        lo = mid
      end
    end
    zeros << (lo + hi) / 2.0
  end
  prev_x = x
  prev_v = v
end
puts "  " + zeros.map { |z| format("%.8f", z) }.join(", ")
gaps = zeros.each_cons(2).map { |a, b| b - a }
puts "  gaps approach pi: " + gaps.map { |g| format("%.5f", g) }.join(", ")

puts format("B(2.5, 1.5) = %.12f", beta(2.5, 1.5))
hits = 0
[0.5, 1.5, 2.5, 0.5, 1.5, 3.5, 0.5].each do |x|
  _v, hit = cached_gamma(cache, x)
  hits += 1 if hit
end
puts "gamma cache: #{cache.size} entries, #{hits} hits"

class Lcg
  attr_reader :state

  def initialize(state)
    @state = state
  end

  def next_float
    @state = (@state * 1103515245 + 12345) % 2147483648
    (@state + 0.5) / 2147483648.0
  end

  def gaussian(mu, sigma)
    u1 = next_float
    u2 = next_float
    mu + sigma * Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math::PI * u2)
  end
end

class Bin
  attr_accessor :lo, :hi, :count

  def initialize(lo, hi, count)
    @lo = lo
    @hi = hi
    @count = count
  end
end

def erf(x)
  # Abramowitz-Stegun 7.1.26
  sign = x < 0.0 ? -1.0 : 1.0
  ax = x.abs
  t = 1.0 / (1.0 + 0.3275911 * ax)
  poly = ((((1.061405429 * t - 1.453152027) * t + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t
  sign * (1.0 - poly * Math.exp(-ax * ax))
end

def normal_cdf(x, mu, sigma) = 0.5 * (1.0 + erf((x - mu) / (sigma * Math.sqrt(2.0))))

def make_bins(xs, nbins)
  lo = xs.min
  hi = xs.max
  width = (hi - lo) / nbins
  bins = (0...nbins).map { |i| Bin.new(lo + i * width, lo + (i + 1) * width, 0) }
  xs.each do |x|
    idx = ((x - lo) / width).floor.clamp(0, nbins - 1)
    bins[idx].count += 1
  end
  bins
end

def sturges(n) = Math.log2(n).ceil + 1

def kde(xs, x, h)
  coef = 1.0 / (xs.size * h * Math.sqrt(2.0 * Math::PI))
  coef * xs.map { |xi| Math.exp(-0.5 * ((x - xi) / h) ** 2) }.sum
end

def inverse_erf(y)
  lo = -6.0
  hi = 6.0
  80.times do
    mid = (lo + hi) / 2.0
    if erf(mid) < y
      lo = mid
    else
      hi = mid
    end
  end
  (lo + hi) / 2.0
end

gen = Lcg.new(20261001)
sample = (0...150).map { gen.gaussian(50.0, 8.0) }
12.times { sample << gen.gaussian(75.0, 2.0) }

n = sample.size
mean = sample.sum / n
sd = Math.sqrt(sample.map { |x| (x - mean) ** 2 }.sum / (n - 1))
puts format("n=%d mean=%.3f sd=%.3f min=%.3f max=%.3f", n, mean, sd, sample.min, sample.max)

nbins = sturges(n)
bins = make_bins(sample, nbins)
peak = bins.map(&:count).max
chi2 = 0.0
bins.each do |b|
  c = b.count
  bar = "#" * (c * 40 / peak)
  expected = n * (normal_cdf(b.hi, mean, sd) - normal_cdf(b.lo, mean, sd))
  chi2 += (c - expected) ** 2 / expected if expected > 0.5
  puts format("[%6.2f, %6.2f) %3d %6.1f %s", b.lo, b.hi, c, expected, bar)
end
puts format("chi-square vs fitted normal: %.2f over %d bins", chi2, nbins)

h = 1.06 * sd * n ** -0.2
puts format("KDE bandwidth (Silverman): %.4f", h)
grid = (0..30).map { |i| 20.0 + i * 2.0 }
dens = grid.map { |x| [x, kde(sample, x, h)] }
modes = []
(1...(dens.size - 1)).each do |i|
  x, d = dens[i]
  modes << [x, d] if d > dens[i - 1][1] && d > dens[i + 1][1]
end
modes.each { |x, d| puts format("density mode near %.1f (%.5f)", x, d) }
puts(modes.size > 1 ? "distribution looks multimodal" : "distribution looks unimodal")

area = 0.0
dens.each_cons(2) do |(x0, d0), (x1, d1)|
  area += (x1 - x0) * (d0 + d1) / 2.0
end
puts format("KDE mass on [20, 80]: %.4f", area)

[0.5, 0.9, 0.99].each do |q|
  sorted = sample.sort
  idx = (q * (n - 1)).floor
  puts format("empirical q%.2f = %.3f, normal q via search = %.3f", q, sorted[idx], mean + sd * Math.sqrt(2.0) * inverse_erf(2.0 * q - 1.0))
end

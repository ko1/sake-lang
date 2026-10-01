class Rng
  attr_accessor :seed

  def initialize(seed)
    @seed = seed
  end

  # xorshift32, kept in 32 bits
  def next_u32
    s = @seed
    s ^= (s << 13) & 0xFFFFFFFF
    s ^= s >> 17
    s ^= (s << 5) & 0xFFFFFFFF
    @seed = s
  end

  def uniform = next_u32 / 4294967296.0
  def range(lo, hi) = lo + (hi - lo) * uniform
end

class Welford
  attr_accessor :n, :mean, :m2

  def initialize(n = 0, mean = 0.0, m2 = 0.0)
    @n = n
    @mean = mean
    @m2 = m2
  end

  def add(x)
    @n += 1
    delta = x - @mean
    @mean += delta / @n
    @m2 += delta * (x - @mean)
    self
  end

  def variance = @n > 1 ? @m2 / (@n - 1) : 0.0
  def stderr = Math.sqrt(variance / @n)
  def ci95 = [@mean - 1.96 * stderr, @mean + 1.96 * stderr]
end

def estimate_pi(rng, n)
  inside = 0
  n.times do
    x = rng.uniform
    y = rng.uniform
    inside += 1 if x * x + y * y <= 1.0
  end
  4.0 * inside / n
end

def mc_integral(rng, a, b, n)
  w = Welford.new
  n.times { w.add((b - a) * yield(rng.range(a, b))) }
  w
end

def antithetic_integral(rng, a, b, n)
  w = Welford.new
  (n / 2).times do
    u = rng.uniform
    x1 = a + (b - a) * u
    x2 = b - (b - a) * u
    w.add((b - a) * (yield(x1) + yield(x2)) / 2.0)
  end
  w
end

rng = Rng.new(2463534242)
puts "pi estimates:"
[100, 500, 2000].each do |n|
  est = estimate_pi(rng, n)
  puts format("  n=%5d pi~%.5f error=%.5f", n, est, (est - Math::PI).abs)
end

puts "integral of exp(-x^2) on [0, 2]:"
reference = 0.8820813907624215
plain = mc_integral(rng, 0.0, 2.0, 1500) { |x| Math.exp(-x * x) }
anti = antithetic_integral(rng, 0.0, 2.0, 1500) { |x| Math.exp(-x * x) }
[["plain", plain], ["antithetic", anti]].each do |label, w|
  lo, hi = w.ci95
  covered = lo <= reference && reference <= hi
  puts format("  %-10s mean=%.5f se=%.5f ci=[%.5f, %.5f] covers=%s", label, w.mean, w.stderr, lo, hi, covered)
end
ratio = plain.variance / (2.0 * anti.variance)
puts format("  variance reduction factor ~ %.2f", ratio)

puts "1-D random walks, 30 steps, 500 walkers:"
ends = Hash.new(0)
max_dist = Welford.new
500.times do
  pos = 0
  far = 0
  30.times do
    pos += rng.uniform < 0.5 ? -1 : 1
    far = pos.abs if pos.abs > far
  end
  ends[pos] += 1
  max_dist.add(far * 1.0)
end
ends.keys.sort.each do |k|
  next if k.abs > 12
  puts format("  %+3d %4d %s", k, ends[k], "*" * (ends[k] / 3))
end
msd = ends.sum { |k, c| k * k * c } / 500.0
puts format("  mean squared displacement %.3f (theory 30)", msd)
puts format("  mean max distance %.3f", max_dist.mean)

puts "buffon's needle (l = 0.8, d = 1):"
hits = 0
trials = 1500
trials.times do
  center = rng.range(0.0, 0.5)
  theta = rng.range(0.0, Math::PI / 2.0)
  hits += 1 if center <= 0.4 * Math.sin(theta)
end
puts format("  hits=%d, pi~%.4f", hits, 2.0 * 0.8 * trials / (hits * 1.0))

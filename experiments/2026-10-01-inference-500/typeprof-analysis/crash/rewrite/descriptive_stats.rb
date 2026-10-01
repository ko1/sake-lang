class Sample
  attr_reader :name, :values

  def initialize(name, values)
    @name = name
    @values = values
  end
end

def mean(xs) = xs.sum / xs.size

def variance(xs)
  m = mean(xs)
  xs.map { |x| (x - m) ** 2 }.sum / (xs.size - 1)
end

def stddev(xs) = Math.sqrt(variance(xs))

def quantile(sorted, q)
  pos = (sorted.size - 1) * q
  lo = pos.floor
  hi = pos.ceil
  return sorted[lo] if lo == hi
  frac = pos - lo
  sorted[lo] * (1.0 - frac) + sorted[hi] * frac
end

def median(xs) = quantile(xs.sort, 0.5)

def skewness(xs)
  m = mean(xs)
  s = stddev(xs)
  n = xs.size
  xs.map { |x| ((x - m) / s) ** 3 }.sum / n
end

def mode_bucket(xs, width)
  counts = Hash.new(0)
  xs.each { |x| counts[(x / width).floor] += 1 }
  best = counts.max_by { |e__| k, v = e__; v }
  return nil unless best
  k, c = best
  [k * width, c]
end

def summarize(sample)
  xs = sample.values
  sorted = xs.sort
  {
    n: xs.size,
    mean: mean(xs),
    median: median(xs),
    sd: stddev(xs),
    min: sorted.first,
    max: sorted.last,
    q1: quantile(sorted, 0.25),
    q3: quantile(sorted, 0.75),
    skew: skewness(xs)
  }
end

def outliers(xs, q1, q3)
  iqr = q3 - q1
  lo = q1 - 1.5 * iqr
  hi = q3 + 1.5 * iqr
  xs.select { |x| x < lo || x > hi }
end

samples = [
  Sample.new("heights", [172.5, 168.0, 181.2, 175.4, 160.9, 190.3, 177.7, 169.8, 174.1, 183.6, 165.2]),
  Sample.new("latency_ms", [12.1, 11.8, 13.0, 12.4, 55.2, 12.9, 11.5, 12.2, 13.4, 12.0, 49.8, 12.6]),
  Sample.new("returns", [0.012, -0.034, 0.008, 0.021, -0.005, 0.017, -0.012, 0.003, 0.029, -0.041])
]

samples.each do |s|
  r = summarize(s)
  r => {n:, mean:, median:, sd:, min:, max:, q1:, q3:, skew:}
  puts "== #{s.name} (n=#{n})"
  puts format("  mean=%.4f median=%.4f sd=%.4f", mean, median, sd)
  puts format("  min=%.4f q1=%.4f q3=%.4f max=%.4f", min, q1, q3, max)
  puts format("  skewness=%.4f", skew)
  out = outliers(s.values, q1, q3)
  if out.empty?
    puts "  no outliers"
  else
    puts "  outliers: #{out.map { |x| format("%.3f", x) }.join(", ")}"
  end
  mb = mode_bucket(s.values, sd)
  if mb
    start, count = mb
    puts format("  densest bucket starts at %.3f with %d values", start, count)
  end
end

all = samples.flat_map { |s| s.values.map { |x| x / s.values.max } }
puts format("normalized pooled mean: %.5f", mean(all))
cv = samples.map { |s| [s.name, stddev(s.values) / mean(s.values).abs] }
cv.sort_by { |e__| name, c = e__; c }.each { |name, c| puts format("cv %-12s %.4f", name, c) }

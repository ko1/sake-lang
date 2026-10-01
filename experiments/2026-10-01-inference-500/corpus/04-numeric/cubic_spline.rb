class OutOfRange < StandardError
  attr_reader :x

  def initialize(message, x)
    super(message)
    @x = x
  end
end

# Thomas algorithm for a tridiagonal system (sub, diag, sup, rhs)
def solve_tridiagonal(sub, diag, sup, rhs)
  n = diag.size
  c = [sup[0] / diag[0]]
  d = [rhs[0] / diag[0]]
  (1...n).each do |i|
    denom = diag[i] - sub[i] * c[i - 1]
    c << (i < n - 1 ? sup[i] / denom : 0.0)
    d << (rhs[i] - sub[i] * d[i - 1]) / denom
  end
  x = d.dup
  (n - 2).downto(0) { |i| x[i] = d[i] - c[i] * x[i + 1] }
  x
end

class Spline
  attr_reader :xs, :ys, :m

  def initialize(xs, ys, m)
    @xs = xs
    @ys = ys
    @m = m
  end

  def self.build(xs, ys)
    n = xs.size
    h = (0...(n - 1)).map { |i| xs[i + 1] - xs[i] }
    sub = [0.0]
    diag = [1.0]
    sup = [0.0]
    rhs = [0.0]
    (1...(n - 1)).each do |i|
      sub << h[i - 1]
      diag << 2.0 * (h[i - 1] + h[i])
      sup << h[i]
      rhs << 6.0 * ((ys[i + 1] - ys[i]) / h[i] - (ys[i] - ys[i - 1]) / h[i - 1])
    end
    sub << 0.0
    diag << 1.0
    sup << 0.0
    rhs << 0.0
    new(xs, ys, solve_tridiagonal(sub, diag, sup, rhs))
  end

  def segment(x)
    lo = 0
    hi = @xs.size - 1
    while hi - lo > 1
      mid = (lo + hi) / 2
      if @xs[mid] <= x
        lo = mid
      else
        hi = mid
      end
    end
    lo
  end

  def value_at(x)
    raise OutOfRange.new("outside the knots", x) if x < @xs.first || x > @xs.last
    i = segment(x)
    h = @xs[i + 1] - @xs[i]
    a = (@xs[i + 1] - x) / h
    b = (x - @xs[i]) / h
    a * @ys[i] + b * @ys[i + 1] + ((a ** 3 - a) * @m[i] + (b ** 3 - b) * @m[i + 1]) * h * h / 6.0
  end

  def slope(x)
    i = segment(x)
    h = @xs[i + 1] - @xs[i]
    a = (@xs[i + 1] - x) / h
    b = (x - @xs[i]) / h
    (@ys[i + 1] - @ys[i]) / h - (3.0 * a * a - 1.0) * h * @m[i] / 6.0 + (3.0 * b * b - 1.0) * h * @m[i + 1] / 6.0
  end
end

def lagrange(xs, ys, x)
  total = 0.0
  xs.each_with_index do |xi, i|
    term = ys[i]
    xs.each_with_index { |xj, j| term *= (x - xj) / (xi - xj) if i != j }
    total += term
  end
  total
end

def linear(xs, ys, x)
  i = xs.find_index { |v| v > x }
  return ys.last if i.nil?
  return ys.first if i == 0
  t = (x - xs[i - 1]) / (xs[i] - xs[i - 1])
  ys[i - 1] + t * (ys[i] - ys[i - 1])
end

def runge(x) = 1.0 / (1.0 + 25.0 * x * x)

knots = (0..10).map { |i| -1.0 + i * 0.2 }
values = knots.map { |x| runge(x) }
sp = Spline.build(knots, values)

puts "     x      exact     spline     linear   lagrange"
probe = (0..8).map { |i| -0.95 + i * 0.2375 }
probe.each do |x|
  puts format("%6.3f %10.6f %10.6f %10.6f %10.6f", x, runge(x), sp.value_at(x), linear(knots, values, x), lagrange(knots, values, x))
end

errs = { "spline" => 0.0, "linear" => 0.0, "lagrange" => 0.0 }
(0..200).each do |k|
  x = -1.0 + k * 0.01
  e = runge(x)
  errs["spline"] = [errs["spline"], (sp.value_at(x) - e).abs].max
  errs["linear"] = [errs["linear"], (linear(knots, values, x) - e).abs].max
  errs["lagrange"] = [errs["lagrange"], (lagrange(knots, values, x) - e).abs].max
end
errs.each { |name, e| puts format("max error %-8s %.6f", name, e) }
best, best_err = errs.min_by { |name, e| e }
puts "best: #{best} (#{format("%.2e", best_err)})"

puts format("slope at 0.3: spline %.5f exact %.5f", sp.slope(0.3), -50.0 * 0.3 / (1.0 + 25.0 * 0.09) ** 2)
puts format("second derivatives at ends: %.3f %.3f", sp.m.first, sp.m.last)

[0.5, 1.5, -1.2].each do |x|
  begin
    puts format("spline(%.2f) = %.6f", x, sp.value_at(x))
  rescue OutOfRange => e
    puts format("spline(%.2f): %s", e.x, e.message)
  end
end

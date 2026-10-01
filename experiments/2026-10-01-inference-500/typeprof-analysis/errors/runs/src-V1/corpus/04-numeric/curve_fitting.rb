class NotPositiveDefinite < StandardError
  attr_reader :row

  def initialize(message, row)
    super(message)
    @row = row
  end
end

module Model
  def residuals(xs, ys) = xs.zip(ys).map { |x, y| y - predict(x) }
  def rmse(xs, ys) = Math.sqrt(residuals(xs, ys).map { |r| r * r }.sum / xs.size)

  def aic(xs, ys)
    n = xs.size
    sse = residuals(xs, ys).map { |r| r * r }.sum
    n * Math.log(sse / n) + 2.0 * nparams
  end
end

class PolyModel
  include Model
  attr_reader :coeffs

  def initialize(coeffs)
    @coeffs = coeffs
  end

  def predict(x) = @coeffs.reverse.reduce(0.0) { |acc, c| acc * x + c }
  def nparams = @coeffs.size
  def describe = "poly deg #{@coeffs.size - 1}: " + @coeffs.map { |c| format("%.4f", c) }.join(", ")
end

class ExpModel
  include Model
  attr_reader :a, :k

  def initialize(a, k)
    @a = a
    @k = k
  end

  def predict(x) = @a * Math.exp(@k * x)
  def nparams = 2
  def describe = format("exp: %.4f * e^(%.4f x)", @a, @k)
end

def cholesky(a)
  n = a.size
  l = Array.new(n) { Array.new(n, 0.0) }
  n.times do |i|
    (0..i).each do |j|
      s = a[i][j]
      j.times { |k| s -= l[i][k] * l[j][k] }
      if i == j
        raise NotPositiveDefinite.new("matrix is not positive definite", i) if s <= 0.0
        l[i][i] = Math.sqrt(s)
      else
        l[i][j] = s / l[j][j]
      end
    end
  end
  l
end

def cholesky_solve(a, b)
  l = cholesky(a)
  n = b.size
  y = b.dup
  n.times do |i|
    i.times { |k| y[i] -= l[i][k] * y[k] }
    y[i] /= l[i][i]
  end
  (n - 1).downto(0) do |i|
    ((i + 1)...n).each { |k| y[i] -= l[k][i] * y[k] }
    y[i] /= l[i][i]
  end
  y
end

def fit_poly(xs, ys, degree)
  m = degree + 1
  ata = (0...m).map { |i| (0...m).map { |j| xs.map { |x| x ** (i + j) }.sum } }
  aty = (0...m).map { |i| xs.zip(ys).map { |x, y| y * x ** i }.sum }
  PolyModel.new(cholesky_solve(ata, aty))
end

def fit_exp(xs, ys)
  return nil if ys.any? { |y| y <= 0.0 }
  c = fit_poly(xs, ys.map { |y| Math.log(y) }, 1).coeffs
  ExpModel.new(Math.exp(c[0]), c[1])
end

xs = (0..11).map { |i| i * 0.5 }
growth = [1.02, 1.30, 1.71, 2.18, 2.80, 3.69, 4.71, 6.08, 7.92, 10.10, 13.05, 16.92]
wave = [0.10, 0.62, 0.95, 0.98, 0.70, 0.22, -0.31, -0.78, -0.99, -0.88, -0.52, 0.02]

[["growth", growth], ["wave", wave]].each do |name, ys|
  puts "== #{name}"
  models = []
  (1..4).each do |d|
    models << fit_poly(xs, ys, d)
  rescue NotPositiveDefinite => e
    puts "  degree #{d}: #{e.message} at row #{e.row}"
  end
  em = fit_exp(xs, ys)
  if em
    models << em
  else
    puts "  exponential model skipped (non-positive data)"
  end
  models.each do |m|
    puts format("  %-48s rmse=%.4f aic=%8.3f", m.describe, m.rmse(xs, ys), m.aic(xs, ys))
  end
  best = models.min_by { |m| m.aic(xs, ys) }
  puts "  best by AIC: #{best.describe}"
  puts format("  prediction at x=6.0: %.3f", best.predict(6.0))
  wx, wr = xs.zip(best.residuals(xs, ys)).max_by { |x, r| r.abs }
  puts format("  largest residual %.4f at x=%.1f", wr, wx)
end

begin
  cholesky([[1.0, 2.0], [2.0, 1.0]])
rescue NotPositiveDefinite => e
  puts "indefinite matrix rejected at row #{e.row}"
end

dup_xs = [1.0, 1.0, 1.0, 1.0]
begin
  fit_poly(dup_xs, [2.0, 2.1, 1.9, 2.0], 2)
rescue NotPositiveDefinite => e
  puts "repeated x values: cannot fit degree 2 (row #{e.row})"
end

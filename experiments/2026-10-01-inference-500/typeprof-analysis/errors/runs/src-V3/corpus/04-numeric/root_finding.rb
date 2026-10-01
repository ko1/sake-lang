class NoConvergence < StandardError
  attr_reader :method_name, :iterations

  def initialize(message, method_name, iterations)
    super(message)
    @method_name = method_name
    @iterations = iterations
  end
end

class BadBracket < StandardError
  attr_reader :a, :b

  def initialize(message, a, b)
    super(message)
    @a = a
    @b = b
  end
end

class Result
  attr_reader :root, :iterations, :method_name

  def initialize(root, iterations, method_name)
    @root = root
    @iterations = iterations
    @method_name = method_name
  end
end

def bisection(a, b, tol)
  fa = yield(a)
  fb = yield(b)
  raise BadBracket.new("f(a) and f(b) have the same sign", a, b) if fa * fb > 0.0
  iter = 0
  while b - a > tol
    iter += 1
    m = (a + b) / 2.0
    fm = yield(m)
    if fa * fm <= 0.0
      b = m
      fb = fm
    else
      a = m
      fa = fm
    end
    raise NoConvergence.new("bisection did not converge", "bisection", iter) if iter > 200
  end
  Result.new((a + b) / 2.0, iter, "bisection")
end

def newton(x0, tol, max_iter)
  x = x0
  max_iter.times do |i|
    fx, dfx = yield(x)
    raise NoConvergence.new("zero derivative at #{format("%.4f", x)}", "newton", i) if dfx.abs < 1e-14
    step = fx / dfx
    x -= step
    return Result.new(x, i + 1, "newton") if step.abs < tol
  end
  raise NoConvergence.new("newton did not converge", "newton", max_iter)
end

def secant(x0, x1, tol, max_iter)
  f0 = yield(x0)
  f1 = yield(x1)
  i = 0
  while i < max_iter
    i += 1
    denom = f1 - f0
    raise NoConvergence.new("flat secant", "secant", i) if denom == 0.0
    x2 = x1 - f1 * (x1 - x0) / denom
    return Result.new(x2, i, "secant") if (x2 - x1).abs < tol
    x0 = x1
    f0 = f1
    x1 = x2
    f1 = yield(x1)
  end
  raise NoConvergence.new("secant did not converge", "secant", max_iter)
end

def report(label, r)
  puts format("%-10s %-9s root=%.10f iters=%d", label, r.method_name, r.root, r.iterations)
end

def cubic(x) = x ** 3 - 2.0 * x - 5.0
def cubic_d(x) = 3.0 * x ** 2 - 2.0

report("cubic", bisection(2.0, 3.0, 1e-10) { |x| cubic(x) })
report("cubic", newton(2.0, 1e-12, 50) { |x| [cubic(x), cubic_d(x)] })
report("cubic", secant(2.0, 3.0, 1e-12, 50) { |x| cubic(x) })

report("cos=x", bisection(0.0, 1.0, 1e-10) { |x| Math.cos(x) - x })
report("cos=x", newton(1.0, 1e-12, 50) { |x| [Math.cos(x) - x, -Math.sin(x) - 1.0] })

# Kepler's equation E - e sin E = M for several mean anomalies
ecc = 0.3
[0.5, 1.0, 2.0, 3.0].each do |m|
  r = newton(m, 1e-13, 30) { |e| [e - ecc * Math.sin(e) - m, 1.0 - ecc * Math.cos(e)] }
  puts format("kepler M=%.2f E=%.10f (%d iters)", m, r.root, r.iterations)
end

# square roots by each method, compared with Math.sqrt
[2.0, 10.0, 0.5].each do |v|
  rs = [
    bisection(0.0, v + 1.0, 1e-12) { |x| x * x - v },
    newton(v, 1e-14, 60) { |x| [x * x - v, 2.0 * x] },
    secant(0.0, v + 1.0, 1e-14, 60) { |x| x * x - v }
  ]
  worst = rs.max_by { |r| (r.root - Math.sqrt(v)).abs }
  total = rs.map(&:iterations).sum
  puts format("sqrt(%.1f): worst=%s err=%.2e total iters=%d", v, worst.method_name, (worst.root - Math.sqrt(v)).abs, total)
end

# failures
begin
  bisection(0.0, 1.0, 1e-8) { |x| x * x + 1.0 }
rescue BadBracket => e
  puts format("bad bracket [%.1f, %.1f]: %s", e.a, e.b, e.message)
end

begin
  newton(0.0, 1e-12, 50) { |x| [x ** 3 - 2.0 * x + 2.0, 3.0 * x ** 2 - 2.0] }
rescue NoConvergence => e
  puts "#{e.method_name} failed after #{e.iterations}: #{e.message}"
end

begin
  newton(0.0, 1e-12, 50) { |x| [x * x - 1.0, 2.0 * x] }
rescue NoConvergence => e
  puts "#{e.method_name} failed after #{e.iterations}: #{e.message}"
end

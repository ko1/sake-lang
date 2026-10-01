class P2
  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def +(b) = P2.new(@x + b.x, @y + b.y)
  def -(b) = P2.new(@x - b.x, @y - b.y)
  def *(k) = P2.new(@x * k, @y * k)
  def norm = Math.hypot(@x, @y)
  def to_s = format("(%.6f, %.6f)", @x, @y)
end

GOLDEN = 0.6180339887498949

def golden_section(a, b, tol)
  c = b - GOLDEN * (b - a)
  d = a + GOLDEN * (b - a)
  fc = yield(c)
  fd = yield(d)
  evals = 2
  while b - a > tol
    if fc < fd
      b = d
      d = c
      fd = fc
      c = b - GOLDEN * (b - a)
      fc = yield(c)
    else
      a = c
      c = d
      fc = fd
      d = a + GOLDEN * (b - a)
      fd = yield(d)
    end
    evals += 1
  end
  [(a + b) / 2.0, evals]
end

def rosenbrock(p) = (1.0 - p.x) ** 2 + 100.0 * (p.y - p.x ** 2) ** 2

def rosen_grad(p)
  x = p.x
  y = p.y
  P2.new(-2.0 * (1.0 - x) - 400.0 * x * (y - x * x), 200.0 * (y - x * x))
end

def gradient_descent(start, max_iter)
  p = start
  iters = 0
  while iters < max_iter
    g = yield(p)
    break if g.norm < 1e-6
    step = 1.0
    f0 = rosenbrock(p)
    gg = g.norm ** 2
    step *= 0.5 while rosenbrock(p - g * step) > f0 - 1e-4 * step * gg
    p -= g * step
    iters += 1
  end
  [p, iters]
end

def nelder_mead(simplex, max_iter, &f)
  pts = simplex
  iters = 0
  while iters < max_iter
    pts = pts.sort_by(&f)
    best = pts[0]
    worst = pts[2]
    fb = f.call(best)
    fw = f.call(worst)
    break if (fw - fb).abs < 1e-14
    centroid = (pts[0] + pts[1]) * 0.5
    refl = centroid + (centroid - worst)
    fr = f.call(refl)
    if fr < fb
      exp = centroid + (refl - centroid) * 2.0
      pts[2] = f.call(exp) < fr ? exp : refl
    elsif fr < f.call(pts[1])
      pts[2] = refl
    else
      contr = centroid + (worst - centroid) * 0.5
      if f.call(contr) < fw
        pts[2] = contr
      else
        pts[1] = best + (pts[1] - best) * 0.5
        pts[2] = best + (pts[2] - best) * 0.5
      end
    end
    iters += 1
  end
  [pts.min_by(&f), iters]
end

puts "golden section:"
[["x^2 - 4x", 0.0, 5.0], ["cos on [2,5]", 2.0, 5.0], ["x + 1/x", 0.1, 4.0]].each do |name, a, b|
  xmin, evals = golden_section(a, b, 1e-8) do |x|
    case name
    in "x^2 - 4x" then x * x - 4.0 * x
    in "cos on [2,5]" then Math.cos(x)
    in "x + 1/x" then x + 1.0 / x
    end
  end
  puts format("  %-13s min at %.7f after %d evaluations", name, xmin, evals)
end

start = P2.new(-1.2, 1.0)
puts "Rosenbrock from #{start}, f=#{format("%.4f", rosenbrock(start))}"
gd, gd_iters = gradient_descent(start, 400) { |q| rosen_grad(q) }
puts format("  gradient descent: %s f=%.3e after %d iterations", gd, rosenbrock(gd), gd_iters)

calls = 0
nm, nm_iters = nelder_mead([start, start + P2.new(0.1, 0.0), start + P2.new(0.0, 0.1)], 2000) do |q|
  calls += 1
  rosenbrock(q)
end
puts format("  nelder-mead: %s f=%.3e after %d iterations, %d calls", nm, rosenbrock(nm), nm_iters, calls)
dist = (nm - P2.new(1.0, 1.0)).norm
puts format("  distance to true minimum: %.2e", dist)

puts "Himmelblau minima from four starts (nelder-mead):"
found = []
[P2.new(1.0, 1.0), P2.new(-1.0, 1.0), P2.new(-1.0, -1.0), P2.new(1.0, -1.0)].each do |s|
  m, it = nelder_mead([s, s + P2.new(0.5, 0.0), s + P2.new(0.0, 0.5)], 1000) do |q|
    (q.x ** 2 + q.y - 11.0) ** 2 + (q.x + q.y ** 2 - 7.0) ** 2
  end
  key = [m.x.round(3), m.y.round(3)]
  found << key unless found.include?(key)
  puts format("  from %s -> (%.4f, %.4f) in %d iterations", s, m.x, m.y, it)
end
puts "distinct minima: #{found.size}"

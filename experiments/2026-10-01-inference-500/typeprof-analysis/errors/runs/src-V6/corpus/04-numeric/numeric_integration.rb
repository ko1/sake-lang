def trapezoid(a, b, n)
  h = (b - a) / n
  sum = (yield(a) + yield(b)) / 2.0
  (1...n).each { |i| sum += yield(a + i * h) }
  sum * h
end

def simpson(a, b, n)
  n += 1 if n.odd?
  h = (b - a) / n
  sum = yield(a) + yield(b)
  (1...n).each do |i|
    w = i.odd? ? 4.0 : 2.0
    sum += w * yield(a + i * h)
  end
  sum * h / 3.0
end

def simpson_step(a, b, fa, fm, fb) = (b - a) / 6.0 * (fa + 4.0 * fm + fb)

def adaptive(a, b, fa, fm, fb, whole, eps, depth, counter, &f)
  m = (a + b) / 2.0
  lm = (a + m) / 2.0
  rm = (m + b) / 2.0
  flm = f.call(lm)
  frm = f.call(rm)
  counter[0] += 2
  left = simpson_step(a, m, fa, flm, fm)
  right = simpson_step(m, b, fm, frm, fb)
  delta = left + right - whole
  if depth <= 0 || delta.abs <= 15.0 * eps
    return left + right + delta / 15.0
  end
  adaptive(a, m, fa, flm, fm, left, eps / 2.0, depth - 1, counter, &f) +
    adaptive(m, b, fm, frm, fb, right, eps / 2.0, depth - 1, counter, &f)
end

def adaptive_simpson(a, b, eps, &f)
  fa = f.call(a)
  fb = f.call(b)
  fm = f.call((a + b) / 2.0)
  counter = [3]
  v = adaptive(a, b, fa, fm, fb, simpson_step(a, b, fa, fm, fb), eps, 40, counter, &f)
  [v, counter[0]]
end

GAUSS_NODES = [
  [0.0, 0.5688888888888889],
  [0.5384693101056831, 0.4786286704993665],
  [0.9061798459386640, 0.2369268850561891]
]

def gauss_legendre(a, b)
  mid = (a + b) / 2.0
  half = (b - a) / 2.0
  total = 0.0
  GAUSS_NODES.each do |x, w|
    if x == 0.0
      total += w * yield(mid)
    else
      total += w * (yield(mid - half * x) + yield(mid + half * x))
    end
  end
  total * half
end

def romberg(a, b, levels, &f)
  table = []
  (0...levels).each do |k|
    n = 2 ** k
    row = [trapezoid(a, b, n, &f)]
    (1..k).each do |j|
      factor = 4.0 ** j
      prev = table[k - 1]
      row << (factor * row[j - 1] - prev[j - 1]) / (factor - 1.0)
    end
    table << row
  end
  table.last.last
end

class Problem
  attr_reader :name, :a, :b, :exact

  def initialize(name, a, b, exact)
    @name = name
    @a = a
    @b = b
    @exact = exact
  end
end

problems = [
  Problem.new("x^2 on [0,3]", 0.0, 3.0, 9.0),
  Problem.new("sin on [0,pi]", 0.0, Math::PI, 2.0),
  Problem.new("exp on [0,1]", 0.0, 1.0, Math.exp(1.0) - 1.0),
  Problem.new("1/(1+x^2) [0,1]", 0.0, 1.0, Math::PI / 4.0),
  Problem.new("sqrt on [0,1]", 0.0, 1.0, 2.0 / 3.0)
]

def integrand(name, x)
  case name
  in "x^2 on [0,3]" then x * x
  in "sin on [0,pi]" then Math.sin(x)
  in "exp on [0,1]" then Math.exp(x)
  in "1/(1+x^2) [0,1]" then 1.0 / (1.0 + x * x)
  in "sqrt on [0,1]" then Math.sqrt(x)
  end
end

puts format("%-16s %11s %11s %11s %11s %11s", "problem", "trap(64)", "simp(64)", "gauss3", "romberg6", "adaptive")
problems.each do |pr|
  name = pr.name
  a = pr.a
  b = pr.b
  exact = pr.exact
  t = trapezoid(a, b, 64) { |x| integrand(name, x) }
  s = simpson(a, b, 64) { |x| integrand(name, x) }
  g = gauss_legendre(a, b) { |x| integrand(name, x) }
  r = romberg(a, b, 6) { |x| integrand(name, x) }
  ad, evals = adaptive_simpson(a, b, 1e-9) { |x| integrand(name, x) }
  errs = [t, s, g, r, ad].map { |v| format("%11.3e", (v - exact).abs) }
  puts format("%-16s %s", name, errs.join(" "))
  puts format("%-16s adaptive used %d evaluations", "", evals)
end

# convergence order of the trapezoid rule for sin
prev = nil
[4, 8, 16, 32, 64].each do |n|
  err = (trapezoid(0.0, Math::PI, n) { |x| Math.sin(x) } - 2.0).abs
  ratio = prev ? prev / err : 0.0
  puts format("trap n=%3d err=%.4e ratio=%.3f", n, err, ratio)
  prev = err
end

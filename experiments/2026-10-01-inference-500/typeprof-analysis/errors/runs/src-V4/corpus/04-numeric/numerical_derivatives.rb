def forward_diff(x, h) = (yield(x + h) - yield(x)) / h
def backward_diff(x, h) = (yield(x) - yield(x - h)) / h
def central_diff(x, h) = (yield(x + h) - yield(x - h)) / (2.0 * h)
def five_point(x, h) = (yield(x - 2.0 * h) - 8.0 * yield(x - h) + 8.0 * yield(x + h) - yield(x + 2.0 * h)) / (12.0 * h)
def second_diff(x, h) = (yield(x + h) - 2.0 * yield(x) + yield(x - h)) / (h * h)

# Richardson table on the central difference
def richardson(x, h, levels, &f)
  table = []
  levels.times do |i|
    hi = h / 2 ** i
    row = [central_diff(x, hi, &f)]
    (1..i).each do |j|
      fac = 4.0 ** j
      row << (fac * row[j - 1] - table[i - 1][j - 1]) / (fac - 1.0)
    end
    table << row
  end
  table.last.last
end

def fn(name, x)
  case name
  in :sin then Math.sin(x)
  in :exp then Math.exp(x)
  in :log then Math.log(x)
  in :rational then 1.0 / (1.0 + x * x)
  end
end

def exact_d(name, x)
  case name
  in :sin then Math.cos(x)
  in :exp then Math.exp(x)
  in :log then 1.0 / x
  in :rational then -2.0 * x / (1.0 + x * x) ** 2
  end
end

x0 = 0.7
puts format("errors at x = %.1f, h = 1e-3:", x0)
puts format("%-9s %10s %10s %10s %10s %10s", "f", "forward", "backward", "central", "5-point", "richard.")
errors = {}
[:sin, :exp, :log, :rational].each do |name|
  ex = exact_d(name, x0)
  vals = [
    forward_diff(x0, 1e-3) { |t| fn(name, t) },
    backward_diff(x0, 1e-3) { |t| fn(name, t) },
    central_diff(x0, 1e-3) { |t| fn(name, t) },
    five_point(x0, 1e-3) { |t| fn(name, t) },
    richardson(x0, 0.1, 4) { |t| fn(name, t) }
  ]
  errs = vals.map { |v| (v - ex).abs }
  errors[name] = errs
  puts format("%-9s %s", name, errs.map { |e| format("%10.2e", e) }.join(" "))
end
labels = ["forward", "backward", "central", "5-point", "richardson"]
best_counts = Hash.new(0)
errors.each do |name, errs|
  best_counts[labels[errs.index(errs.min)]] += 1
end
puts "most accurate: #{best_counts.map { |l, c| "#{l} x#{c}" }.join(", ")}"

puts "central difference of sin at 1.0 vs step size:"
best_h = nil
best_err = nil
(1..12).each do |k|
  h = 10.0 ** -k
  err = (central_diff(1.0, h) { |t| Math.sin(t) } - Math.cos(1.0)).abs
  if !best_err     || err < best_err
    best_err = err
    best_h = h
  end
  puts format("  h=1e-%02d err=%.3e", k, err) if k.even?
end
puts format("  best h = %.0e (err %.2e); theory ~ cbrt(eps) = %.1e", best_h, best_err, Math.cbrt(Float::EPSILON))

puts format("second derivative of exp at 0: %.8f", second_diff(0.0, 1e-4) { |t| Math.exp(t) })

# Jacobian of F(x, y) = (x^2 y - 1, sin(x) + y^3) by central differences
def big_f(v)
  x, y = v
  [x * x * y - 1.0, Math.sin(x) + y ** 3]
end

def jacobian(v, h)
  n = v.size
  cols = (0...n).map do |j|
    plus = v.dup
    minus = v.dup
    plus[j] += h
    minus[j] -= h
    fp = big_f(plus)
    fm = big_f(minus)
    fp.each_index.map { |i| (fp[i] - fm[i]) / (2.0 * h) }
  end
  (0...n).map { |i| (0...n).map { |j| cols[j][i] } }
end

pt = [1.2, 0.8]
jac = jacobian(pt, 1e-5)
px, py = pt
exact = [[2.0 * px * py, px * px], [Math.cos(px), 3.0 * py * py]]
jac.each_with_index do |row, i|
  puts format("J row %d: %s  (exact %s)", i, row.map { |v| format("%.6f", v) }.join(" "), exact[i].map { |v| format("%.6f", v) }.join(" "))
end

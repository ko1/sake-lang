def lerp((px, py), (qx, qy), t) = [px + (qx - px) * t, py + (qy - py) * t]

def dist((px, py), (qx, qy)) = Math.hypot(qx - px, qy - py)

def de_casteljau(ctrl, t)
  pts = ctrl
  pts = pts.each_cons(2).map { |p, q| lerp(p, q, t) } while pts.size > 1
  pts[0]
end

def binomial(n, k)
  return 1 if k == 0 || k == n
  (1..k).reduce(1) { |acc, i| acc * (n - k + i) / i }
end

def bernstein_point(ctrl, t)
  n = ctrl.size - 1
  x = 0.0
  y = 0.0
  ctrl.each_with_index do |(px, py), i|
    b = binomial(n, i) * t ** i * (1.0 - t) ** (n - i)
    x += b * px
    y += b * py
  end
  [x, y]
end

def split_curve(ctrl, t)
  left = [ctrl.first]
  right = [ctrl.last]
  pts = ctrl
  while pts.size > 1
    pts = pts.each_cons(2).map { |p, q| lerp(p, q, t) }
    left << pts.first
    right.unshift(pts.last)
  end
  [left, right]
end

def polyline_length(ctrl, segments)
  prev = de_casteljau(ctrl, 0.0)
  total = 0.0
  (1..segments).each do |i|
    cur = de_casteljau(ctrl, i * 1.0 / segments)
    total += dist(prev, cur)
    prev = cur
  end
  total
end

def adaptive_length(ctrl, tol, depth)
  chord = dist(ctrl.first, ctrl.last)
  net = ctrl.each_cons(2).reduce(0.0) { |acc, (p, q)| acc + dist(p, q) }
  return (chord + net) / 2.0 if net - chord < tol || depth == 0
  l, r = split_curve(ctrl, 0.5)
  adaptive_length(l, tol / 2.0, depth - 1) + adaptive_length(r, tol / 2.0, depth - 1)
end

def bounding_box(ctrl, samples)
  pts = (0..samples).map { |i| de_casteljau(ctrl, i * 1.0 / samples) }
  xs = pts.map(&:first)
  ys = pts.map(&:last)
  { min_x: xs.min, max_x: xs.max, min_y: ys.min, max_y: ys.max }
end

def closest_t(ctrl, target)
  best = (0..20).min_by { |i| dist(de_casteljau(ctrl, i / 20.0), target) }
  lo = [0.0, (best - 1) / 20.0].max
  hi = [1.0, (best + 1) / 20.0].min
  30.times do
    m1 = lo + (hi - lo) / 3.0
    m2 = hi - (hi - lo) / 3.0
    if dist(de_casteljau(ctrl, m1), target) < dist(de_casteljau(ctrl, m2), target)
      hi = m2
    else
      lo = m1
    end
  end
  (lo + hi) / 2.0
end

def fmt_pt((x, y)) = format("(%.4f, %.4f)", x, y)

curves = [
  ["quadratic", [[0.0, 0.0], [1.0, 2.0], [2.0, 0.0]]],
  ["cubic S", [[0.0, 0.0], [1.0, 3.0], [2.0, -3.0], [3.0, 0.0]]],
  ["quartic loop", [[0.0, 0.0], [4.0, 4.0], [-1.0, 4.0], [3.0, 0.0], [2.0, 2.0]]],
  ["straight cubic", [[0.0, 0.0], [1.0, 1.0], [2.0, 2.0], [3.0, 3.0]]]
]

curves.each do |name, ctrl|
  puts "== #{name} (degree #{ctrl.size - 1})"
  mid = de_casteljau(ctrl, 0.5)
  diff = dist(mid, bernstein_point(ctrl, 0.5))
  puts "  B(0.5) = #{fmt_pt(mid)}, Bernstein agrees to #{format("%.1e", diff)}"
  l16 = polyline_length(ctrl, 16)
  l128 = polyline_length(ctrl, 128)
  la = adaptive_length(ctrl, 1e-4, 12)
  puts format("  length: 16 segs %.6f, 128 segs %.6f, adaptive %.6f", l16, l128, la)
  bounding_box(ctrl, 100) => {min_x:, max_x:, min_y:, max_y:}
  puts format("  bbox x [%.4f, %.4f] y [%.4f, %.4f]", min_x, max_x, min_y, max_y)
  left, right = split_curve(ctrl, 0.3)
  joined = dist(left.last, right.first)
  check = dist(de_casteljau(left, 0.5), de_casteljau(ctrl, 0.15))
  puts format("  split at 0.3: joint gap %.1e, left(0.5) vs B(0.15) %.1e", joined, check)
  t = closest_t(ctrl, [1.5, 1.0])
  puts format("  closest to (1.5, 1.0): t=%.5f at %s, distance %.5f", t, fmt_pt(de_casteljau(ctrl, t)), dist(de_casteljau(ctrl, t), [1.5, 1.0]))
end

puts "binomial row 6: #{(0..6).map { |k| binomial(6, k) }}"

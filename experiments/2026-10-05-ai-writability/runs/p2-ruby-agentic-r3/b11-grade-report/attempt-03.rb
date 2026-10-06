def rh(r) = (r * 10 + Rational(1, 2)).floor
weights = {}
errs = []
studs = {}
$stdin.each_line.with_index(1) do |raw, n|
  l = raw.strip
  next if l.empty? || l.start_with?("#")
  f = l.split
  if f.size == 3 && f[0] == "weight"
    c, w = f[1], f[2]
    if w !~ /\A\d+\z/ || !(1..100).cover?(w.to_i)
      errs << "line #{n}: bad weight #{w}"
    elsif weights.key?(c)
      errs << "line #{n}: duplicate category #{c}"
    else
      weights[c] = w.to_i
    end
    next
  end
  if f.size != 3
    errs << "line #{n}: bad format"; next
  end
  s, c, sc = f
  unless weights.key?(c)
    errs << "line #{n}: unknown category #{c}"; next
  end
  md = /\A(\d+|-|EX)\/(\d+)\z/.match(sc)
  pp_ = md && md[1]; m = md && md[2].to_i
  if md && m > 0 && (pp_ !~ /\d/ || pp_.to_i <= m)
    kind = pp_ == "-" ? :miss : pp_ == "EX" ? :ex : :ok
    p_ = pp_.to_i
  else
    errs << "line #{n}: bad score #{sc}"; next
  end
  st = (studs[s] ||= { cats: {}, miss: 0 })
  next if kind == :ex
  a = (st[:cats][c] ||= [0, 0])
  if kind == :miss
    st[:miss] += 1
  else
    a[0] += p_
  end
  a[1] += m
end
rows = studs.map do |name, st|
  num = 0r; den = 0
  st[:cats].each do |c, (p_, m)|
    next if m == 0
    num += weights[c] * Rational(p_, m); den += weights[c]
  end
  pct = den > 0 ? num * 100 / den : nil
  [name, pct, st[:miss]]
end
rows.each { |r| r[3] = r[1] && rh(r[1]) }
w = [7, *rows.map { |r| r[0].size }].max
puts errs
puts "Student".ljust(w) + "  Score  G  Missing"
with, without = rows.partition { |r| r[3] }
with = with.sort_by { |r| [-r[3], r[0]] }
without = without.sort_by { |r| r[0] }
(with + without).each do |name, _, miss, t|
  if t
    g = t >= 900 ? "A" : t >= 800 ? "B" : t >= 700 ? "C" : t >= 600 ? "D" : "F"
    sc = format("%d.%d", t / 10, t % 10).rjust(5)
  else
    g = "-"; sc = "  n/a"
  end
  puts "#{name.ljust(w)}  #{sc}  #{g}  #{miss.to_s.rjust(7)}"
end
ps = rows.map { |r| r[1] }.compact
puts "class average: " + (ps.empty? ? "n/a" : (t = rh(ps.sum / ps.size); format("%d.%d", t / 10, t % 10)))

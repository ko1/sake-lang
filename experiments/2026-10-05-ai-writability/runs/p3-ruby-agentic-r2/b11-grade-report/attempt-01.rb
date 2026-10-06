def r1(x)
  (x * 10 + Rational(1, 2)).floor
end

def fmt(t)
  format("%d.%d", t / 10, t % 10)
end

weights = {}
errs = []
studs = {}
$stdin.each_line.with_index(1) do |raw, n|
  line = raw.strip
  next if line.empty? || line.start_with?("#")
  f = line.split
  if f[0] == "weight"
    if f.size != 3
      errs << "line #{n}: bad format"
    elsif !(f[2] =~ /\A\d+\z/ && (1..100).cover?(f[2].to_i))
      errs << "line #{n}: bad weight #{f[2]}"
    elsif weights.key?(f[1])
      errs << "line #{n}: duplicate category #{f[1]}"
    else
      weights[f[1]] = f[2].to_i
    end
    next
  end
  if f.size != 3
    errs << "line #{n}: bad format"
    next
  end
  s, c, sc = f
  unless weights.key?(c)
    errs << "line #{n}: unknown category #{c}"
    next
  end
  m = sc.match(/\A(\d+|EX|-)\/(\d+)\z/)
  ok = m && m[2].to_i > 0 && (m[1] !~ /\A\d+\z/ || m[1].to_i <= m[2].to_i)
  unless ok
    errs << "line #{n}: bad score #{sc}"
    next
  end
  st = (studs[s] ||= { cats: {}, miss: 0 })
  p = m[1]
  mx = m[2].to_i
  next if p == "EX"
  e = (st[:cats][c] ||= [0, 0])
  if p == "-"
    st[:miss] += 1
  else
    e[0] += p.to_i
  end
  e[1] += mx
end

rows = studs.map do |name, st|
  num = Rational(0)
  den = 0
  st[:cats].each do |c, (p, m)|
    num += Rational(weights[c] * p, m)
    den += weights[c]
  end
  pct = den > 0 ? num * 100 / den : nil
  [name, pct, pct && r1(pct), st[:miss]]
end

out = errs.dup
w = [7, *studs.keys.map(&:size)].max
out << "Student".ljust(w) + "  Score  G  Missing"
with, without = rows.partition { |r| r[1] }
with.sort_by! { |r| [-r[2], r[0]] }
without.sort_by! { |r| r[0] }
(with + without).each do |name, pct, t, miss|
  if pct
    g = t >= 900 ? "A" : t >= 800 ? "B" : t >= 700 ? "C" : t >= 600 ? "D" : "F"
    out << "#{name.ljust(w)}  #{fmt(t).rjust(5)}  #{g}  #{miss.to_s.rjust(7)}"
  else
    out << "#{name.ljust(w)}  #{'n/a'.rjust(5)}  -  #{miss.to_s.rjust(7)}"
  end
end
if with.empty?
  out << "class average: n/a"
else
  avg = with.sum { |r| r[1] } / with.size
  out << "class average: #{fmt(r1(avg))}"
end
puts out

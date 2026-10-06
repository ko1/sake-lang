weights = {}
entries = Hash.new { |h, k| h[k] = [] }
errors = []
known = {}
missing = Hash.new(0)

$stdin.each_line.with_index(1) do |raw, n|
  line = raw.strip
  next if line.empty? || line.start_with?("#")
  f = line.split(/\s+/)
  if f.size == 3 && f[0] == "weight"
    cat, w = f[1], f[2]
    if w !~ /\A\d+\z/ || !(1..100).cover?(w.to_i)
      errors << "line #{n}: bad weight #{w}"
    elsif weights.key?(cat)
      errors << "line #{n}: duplicate category #{cat}"
    else
      weights[cat] = w.to_i
    end
    next
  end
  if f.size != 3
    errors << "line #{n}: bad format"
    next
  end
  st, cat, sc = f
  unless weights.key?(cat)
    errors << "line #{n}: unknown category #{cat}"
    next
  end
  md = /\A(\d+|EX|-)\/(\d+)\z/.match(sc)
  m = md && md[2].to_i
  pt = md && md[1]
  ok = md && m > 0 && (pt == "EX" || pt == "-" || pt.to_i <= m)
  unless ok
    errors << "line #{n}: bad score #{sc}"
    next
  end
  known[st] = true
  if pt == "EX"
    next
  elsif pt == "-"
    missing[st] += 1
    entries[[st, cat]] << [0, m]
  else
    entries[[st, cat]] << [pt.to_i, m]
  end
end

rows = known.keys.map do |st|
  num = Rational(0)
  den = 0
  weights.each do |cat, w|
    es = entries[[st, cat]]
    next if es.empty?
    sp = es.sum { |e| e[0] }
    sm = es.sum { |e| e[1] }
    num += Rational(w * sp, sm)
    den += w
  end
  pct = den > 0 ? num * 100 / den : nil
  t = pct ? (pct * 10 + Rational(1, 2)).floor : nil
  [st, pct, t, missing[st]]
end

with = rows.select { |r| r[1] }.sort_by { |r| [-r[2], r[0]] }
without = rows.reject { |r| r[1] }.sort_by { |r| r[0] }

grade = lambda do |t|
  if t >= 900 then "A"
  elsif t >= 800 then "B"
  elsif t >= 700 then "C"
  elsif t >= 600 then "D"
  else "F"
  end
end

out = errors.dup
wd = [7, known.keys.map(&:size).max || 0].max
out << "Student".ljust(wd) + "  Score  G  Missing"
(with + without).each do |st, pct, t, ms|
  if pct
    ps = "#{t / 10}.#{t % 10}".rjust(5)
    g = grade.call(t)
  else
    ps = "n/a".rjust(5)
    g = "-"
  end
  out << "#{st.ljust(wd)}  #{ps}  #{g}  #{ms.to_s.rjust(7)}"
end
if with.empty?
  out << "class average: n/a"
else
  avg = with.sum { |r| r[1] } / with.size
  t = (avg * 10 + Rational(1, 2)).floor
  out << "class average: #{t / 10}.#{t % 10}"
end
puts out

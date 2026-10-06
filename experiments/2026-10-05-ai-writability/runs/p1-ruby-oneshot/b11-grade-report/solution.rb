weights = {}
students = {}
errors = []
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
  m = /\A(\d+|EX|-)\/(\d+)\z/.match(sc)
  if m.nil? || m[2].to_i <= 0 || (m[1] =~ /\A\d/ && m[1].to_i > m[2].to_i)
    errors << "line #{n}: bad score #{sc}"
    next
  end
  s = (students[st] ||= { cats: {}, missing: 0 })
  next if m[1] == "EX"
  c = (s[:cats][cat] ||= [0, 0])
  if m[1] == "-"
    s[:missing] += 1
  else
    c[0] += m[1].to_i
  end
  c[1] += m[2].to_i
end

rows = students.map do |name, s|
  pct = nil
  unless s[:cats].empty?
    num = Rational(0)
    den = 0
    s[:cats].each do |cat, (p, mx)|
      num += Rational(weights[cat] * p, mx)
      den += weights[cat]
    end
    pct = num * 100 / den
  end
  tenths = pct && (pct * 10 + Rational(1, 2)).floor
  { name: name, pct: pct, tenths: tenths, missing: s[:missing] }
end

fmt = ->(t) { format("%d.%d", t / 10, t % 10) }
grade = lambda do |t|
  if t >= 900 then "A"
  elsif t >= 800 then "B"
  elsif t >= 700 then "C"
  elsif t >= 600 then "D"
  else "F"
  end
end

w = [7, *rows.map { |r| r[:name].size }].max
with = rows.select { |r| r[:pct] }.sort_by { |r| [-r[:tenths], r[:name]] }
without = rows.reject { |r| r[:pct] }.sort_by { |r| r[:name] }

out = errors.dup
out << "#{"Student".ljust(w)}  Score  G  Missing"
(with + without).each do |r|
  if r[:pct]
    out << "#{r[:name].ljust(w)}  #{fmt.(r[:tenths]).rjust(5)}  #{grade.(r[:tenths])}  #{r[:missing].to_s.rjust(7)}"
  else
    out << "#{r[:name].ljust(w)}  #{"n/a".rjust(5)}  -  #{r[:missing].to_s.rjust(7)}"
  end
end
if with.empty?
  out << "class average: n/a"
else
  avg = with.sum(Rational(0)) { |r| r[:pct] } / with.size
  out << "class average: #{fmt.((avg * 10 + Rational(1, 2)).floor)}"
end
puts out

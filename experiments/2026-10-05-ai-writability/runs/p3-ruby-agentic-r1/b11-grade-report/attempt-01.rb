errs = []
weights = {}
data = {} # student => {cat => [pts, max]}
miss = Hash.new(0)
$stdin.each_line.with_index(1) do |raw, n|
  line = raw.strip
  next if line.empty? || line.start_with?("#")
  f = line.split
  if f.size == 3 && f[0] == "weight"
    w = f[2]
    if w !~ /\A\d+\z/ || !(1..100).cover?(w.to_i)
      errs << "line #{n}: bad weight #{w}"
    elsif weights.key?(f[1])
      errs << "line #{n}: duplicate category #{f[1]}"
    else
      weights[f[1]] = w.to_i
    end
    next
  end
  if f.size != 3
    errs << "line #{n}: bad format"; next
  end
  st, cat, sc = f
  unless weights.key?(cat)
    errs << "line #{n}: unknown category #{cat}"; next
  end
  unless sc =~ /\A(\d+|EX|-)\/(\d+)\z/ && $2.to_i > 0 && ($1 !~ /\d/ || $1.to_i <= $2.to_i)
    errs << "line #{n}: bad score #{sc}"; next
  end
  p, m = $1, $2.to_i
  data[st] ||= {}
  next if p == "EX"
  c = (data[st][cat] ||= [0, 0])
  if p == "-"
    miss[st] += 1
  else
    c[0] += p.to_i
  end
  c[1] += m
end
rows = data.map do |st, cats|
  num = Rational(0); den = 0
  cats.each do |cat, (s, m)|
    next if m == 0
    num += weights[cat] * Rational(s, m); den += weights[cat]
  end
  pct = den > 0 ? 100 * num / den : nil
  [st, pct, pct && ((pct * 10 + Rational(1, 2)).floor)]
end
w = [7, *data.keys.map(&:size)].max
grade = ->(t) { t >= 900 ? "A" : t >= 800 ? "B" : t >= 700 ? "C" : t >= 600 ? "D" : "F" }
with = rows.select { |r| r[1] }.sort_by { |r| [-r[2], r[0]] }
without = rows.reject { |r| r[1] }.sort_by { |r| r[0] }
out = errs.dup
out << "Student".ljust(w) + "  Score  G  Missing"
with.each do |st, _, t|
  out << "#{st.ljust(w)}  #{format('%d.%d', t / 10, t % 10).rjust(5)}  #{grade[t]}  #{miss[st].to_s.rjust(7)}"
end
without.each do |st, _, _|
  out << "#{st.ljust(w)}  #{'n/a'.rjust(5)}  -  #{miss[st].to_s.rjust(7)}"
end
if with.empty?
  out << "class average: n/a"
else
  avg = with.sum { |r| r[1] } / with.size
  t = (avg * 10 + Rational(1, 2)).floor
  out << "class average: #{t / 10}.#{t % 10}"
end
puts out

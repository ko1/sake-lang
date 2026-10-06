def tenths(r)
  (r * 10 + Rational(1, 2)).floor
end

def fmt(t)
  "#{t / 10}.#{t % 10}"
end

weights = {}
entries = {}
missing = Hash.new(0)
errors = []

$stdin.each_line.with_index(1) do |raw, n|
  line = raw.strip
  next if line.empty? || line.start_with?("#")
  f = line.split
  if f[0] == "weight" && f.size == 3
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
  if sc =~ /\A(\d+|-|EX)\/(\d+)\z/ && $2.to_i > 0 && ($1 !~ /\d/ || $1.to_i <= $2.to_i)
    if $1 == "EX"
      entries[st] ||= {}
      next
    end
    p_ = $1 == "-" ? 0 : $1.to_i
    m_ = $2.to_i
    missing[st] += 1 if $1 == "-"
    a = ((entries[st] ||= {})[cat] ||= [0, 0])
    a[0] += p_
    a[1] += m_
  else
    errors << "line #{n}: bad score #{sc}"
  end
end

pct = {}
entries.each do |st, cats|
  next if cats.empty?
  num = Rational(0)
  den = 0
  cats.each do |c, (p, m)|
    num += weights[c] * Rational(p, m)
    den += weights[c]
  end
  pct[st] = 100 * num / den
end

grade = lambda do |t|
  t >= 900 ? "A" : t >= 800 ? "B" : t >= 700 ? "C" : t >= 600 ? "D" : "F"
end

w = [7, *entries.keys.map(&:size)].max
rows = entries.keys
with = rows.select { |s| pct[s] }.sort_by { |s| [-tenths(pct[s]), s] }
without = (rows - with).sort

out = errors.dup
out << "Student".ljust(w) + "  Score  G  Missing"
with.each do |s|
  t = tenths(pct[s])
  out << "#{s.ljust(w)}  #{fmt(t).rjust(5)}  #{grade.call(t)}  #{missing[s].to_s.rjust(7)}"
end
without.each do |s|
  out << "#{s.ljust(w)}  #{'n/a'.rjust(5)}  -  #{missing[s].to_s.rjust(7)}"
end
if with.empty?
  out << "class average: n/a"
else
  avg = pct.values.sum(Rational(0)) / pct.size
  out << "class average: #{fmt(tenths(avg))}"
end
puts out

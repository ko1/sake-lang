lines = $stdin.read.split("\n", -1)
errors = []
weights = {}
entries = {} # student => { cat => [pts, max] }
missing = Hash.new(0)
known = []
lines.each_with_index do |raw, i|
  n = i + 1
  line = raw.strip
  next if line.empty? || line.start_with?("#")
  f = line.split
  if f[0] == "weight" && f.size == 3
    w = f[2]
    if w !~ /\A\d+\z/ || w.to_i < 1 || w.to_i > 100
      errors << "line #{n}: bad weight #{w}"
    elsif weights.key?(f[1])
      errors << "line #{n}: duplicate category #{f[1]}"
    else
      weights[f[1]] = w.to_i
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
  kind = nil
  pts = 0
  mx = 0
  if sc == "EX"
    kind = :ex
  elsif sc == "-"
    kind = :miss
  elsif sc =~ /\A(\d+|EX|-)\/(\d+)\z/
    p_, m_ = $1, $2.to_i
    if m_ > 0
      if p_ == "EX"
        kind = :ex
      elsif p_ == "-"
        kind = :miss
        mx = m_
      elsif p_.to_i <= m_
        kind = :ok
        pts = p_.to_i
        mx = m_
      end
    end
  end
  if kind.nil?
    errors << "line #{n}: bad score #{sc}"
    next
  end
  unless entries.key?(st)
    entries[st] = {}
    known << st
  end
  next if kind == :ex
  missing[st] += 1 if kind == :miss
  e = (entries[st][cat] ||= [0, 0])
  e[0] += pts
  e[1] += mx
end

half_up_tenths = lambda { |r| (r * 10 + Rational(1, 2)).floor }

pct = {}
known.each do |st|
  num = Rational(0)
  den = 0
  entries[st].each do |cat, (p_, m_)|
    next if m_ == 0
    num += Rational(p_, m_) * weights[cat]
    den += weights[cat]
  end
  pct[st] = num * 100 / den if den > 0
end

w = [7, *known.map(&:size)].max
out = errors.dup
out << "Student".ljust(w) + "  Score  G  Missing"
with = known.select { |s| pct[s] }
without = known.reject { |s| pct[s] }
rt = {}
with.each { |s| rt[s] = half_up_tenths.call(pct[s]) }
with = with.sort_by { |s| [-rt[s], s] }
without = without.sort
grade = lambda do |t|
  if t >= 900 then "A"
  elsif t >= 800 then "B"
  elsif t >= 700 then "C"
  elsif t >= 600 then "D"
  else "F"
  end
end
with.each do |s|
  t = rt[s]
  ps = "#{t / 10}.#{t % 10}"
  out << "#{s.ljust(w)}  #{ps.rjust(5)}  #{grade.call(t)}  #{missing[s].to_s.rjust(7)}"
end
without.each do |s|
  out << "#{s.ljust(w)}  #{'n/a'.rjust(5)}  -  #{missing[s].to_s.rjust(7)}"
end
if pct.empty?
  out << "class average: n/a"
else
  avg = pct.values.sum(Rational(0)) / pct.size
  t = half_up_tenths.call(avg)
  out << "class average: #{t / 10}.#{t % 10}"
end
puts out

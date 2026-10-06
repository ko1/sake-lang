weights = {}
students = {}
missing = Hash.new(0)
errors = []
$stdin.each_line.with_index(1) do |raw, n|
  line = raw.strip
  next if line.empty? || line.start_with?("#")
  f = line.split
  if f[0] == "weight" && f.size == 3
    c, w = f[1], f[2]
    if w !~ /\A\d+\z/ || w.to_i < 1 || w.to_i > 100
      errors << "line #{n}: bad weight #{w}"
    elsif weights.key?(c)
      errors << "line #{n}: duplicate category #{c}"
    else
      weights[c] = w.to_i
    end
    next
  end
  if f.size != 3
    errors << "line #{n}: bad format"
    next
  end
  s, c, sc = f
  unless weights.key?(c)
    errors << "line #{n}: unknown category #{c}"
    next
  end
  entry = nil
  if sc == "EX"
    entry = nil
  elsif sc =~ /\A(\d+|-)\/(\d+)\z/ && $2.to_i > 0 && ($1 == "-" || $1.to_i <= $2.to_i)
    if $1 == "-"
      missing[s] += 1
      entry = [0, $2.to_i]
    else
      entry = [$1.to_i, $2.to_i]
    end
  else
    errors << "line #{n}: bad score #{sc}"
    next
  end
  students[s] ||= {}
  if entry
    e = (students[s][c] ||= [0, 0])
    e[0] += entry[0]
    e[1] += entry[1]
  end
end

rows = students.map do |name, cats|
  if cats.empty?
    [name, nil, nil]
  else
    tw = cats.keys.sum { |c| weights[c] }
    num = cats.sum { |c, (p, m)| weights[c] * Rational(p, m) }
    pct = num * 100 / tw
    [name, pct, ((pct * 10) + Rational(1, 2)).floor]
  end
end

out = errors.dup
w = [7, *rows.map { |r| r[0].size }].max
out << "Student".ljust(w) + "  Score  G  Missing"
with = rows.select { |r| r[1] }.sort_by { |r| [-r[2], r[0]] }
without = rows.reject { |r| r[1] }.sort_by { |r| r[0] }
(with + without).each do |name, pct, t|
  if pct
    g = t >= 900 ? "A" : t >= 800 ? "B" : t >= 700 ? "C" : t >= 600 ? "D" : "F"
    ps = "#{t / 10}.#{t % 10}".rjust(5)
  else
    g = "-"
    ps = "n/a".rjust(5)
  end
  out << "#{name.ljust(w)}  #{ps}  #{g}  #{missing[name].to_s.rjust(7)}"
end
pcts = with.map { |r| r[1] }
if pcts.empty?
  out << "class average: n/a"
else
  t = ((pcts.sum / pcts.size * 10) + Rational(1, 2)).floor
  out << "class average: #{t / 10}.#{t % 10}"
end
puts out

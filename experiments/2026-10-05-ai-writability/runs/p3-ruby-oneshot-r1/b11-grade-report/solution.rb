weights = {}
errors = []
data = {}
missing = Hash.new(0)
known = []
STDIN.each_line.with_index(1) do |raw, n|
  line = raw.strip
  next if line.empty? || line.start_with?('#')
  f = line.split
  if f.size == 3 && f[0] == 'weight'
    c = f[1]; w = f[2]
    if w !~ /\A\d+\z/ || !(1..100).cover?(w.to_i)
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
  kind = nil
  p = m = 0
  if sc == 'EX'
    kind = :ex
  elsif sc == '-'
    kind = :miss0
  elsif sc =~ /\A(\d+|-)\/(\d+)\z/
    m = $2.to_i
    if $1 == '-'
      kind = :miss if m > 0
    else
      p = $1.to_i
      kind = :score if m > 0 && p <= m
    end
  end
  if kind.nil?
    errors << "line #{n}: bad score #{sc}"
    next
  end
  unless data.key?(s)
    data[s] = {}
    known << s
  end
  case kind
  when :score
    e = (data[s][c] ||= [0, 0]); e[0] += p; e[1] += m
  when :miss
    e = (data[s][c] ||= [0, 0]); e[1] += m
    missing[s] += 1
  when :miss0
    missing[s] += 1
  end
end

def tenths(r)
  (r * 10 + Rational(1, 2)).floor
end

rows = known.uniq.map do |s|
  num = Rational(0); den = 0
  data[s].each do |c, (p, m)|
    next if m == 0
    num += weights[c] * Rational(p, m)
    den += weights[c]
  end
  pct = den > 0 ? 100 * num / den : nil
  [s, pct, pct && tenths(pct)]
end

out = errors.dup
w = [7, known.map(&:size).max || 0].max
out << "Student".ljust(w) + "  Score  G  Missing"
with, without = rows.partition { |r| r[1] }
with.sort_by! { |r| [-r[2], r[0]] }
without.sort_by! { |r| r[0] }
(with + without).each do |s, pct, t|
  if pct
    sc = "#{t / 10}.#{t % 10}"
    g = t >= 900 ? 'A' : t >= 800 ? 'B' : t >= 700 ? 'C' : t >= 600 ? 'D' : 'F'
  else
    sc = 'n/a'; g = '-'
  end
  out << "#{s.ljust(w)}  #{sc.rjust(5)}  #{g}  #{missing[s].to_s.rjust(7)}"
end
if with.empty?
  out << "class average: n/a"
else
  t = tenths(with.sum { |r| r[1] } / with.size)
  out << "class average: #{t / 10}.#{t % 10}"
end
puts out

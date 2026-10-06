def r1(x) = ((x * 10) + Rational(1, 2)).floor
weights = {}
errors = []
studs = {} # name => {cat => [pts, max]}, missing
missing = Hash.new(0)
$stdin.each_line.with_index(1) do |raw, n|
  line = raw.strip
  next if line.empty? || line.start_with?("#")
  f = line.split
  if f[0] == "weight" && f.size == 3
    w = f[2]
    if !w.match?(/\A\d+\z/) || !(1..100).cover?(w.to_i)
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
  s, c, sc = f
  unless weights.key?(c)
    errors << "line #{n}: unknown category #{c}"
    next
  end
  p_, m = nil, nil
  kind = nil
  if sc == "EX" then kind = :ex
  elsif sc == "-" then kind = :miss0
  elsif (md = sc.match(%r{\A(\d+|-)/(\d+)\z}))
    m = md[2].to_i
    if m > 0
      if md[1] == "-" then kind = :miss
      elsif md[1].to_i <= m then kind = :ok; p_ = md[1].to_i
      end
    end
  end
  unless kind
    errors << "line #{n}: bad score #{sc}"
    next
  end
  h = (studs[s] ||= {})
  next if kind == :ex
  e = (h[c] ||= [0, 0])
  case kind
  when :ok then e[0] += p_; e[1] += m
  when :miss then e[1] += m; missing[s] += 1
  when :miss0 then missing[s] += 1
  end
end

pct = {}
studs.each do |s, h|
  num = Rational(0); den = 0
  h.each do |c, (p, m)|
    next if m == 0
    num += weights[c] * Rational(p, m); den += weights[c]
  end
  pct[s] = den > 0 ? num * 100 / den : nil
end

w = [7, studs.keys.map(&:size).max || 0].max
rows = studs.keys.sort_by { |s| pct[s] ? [0, -r1(pct[s]), s] : [1, 0, s] }
out = errors.dup
out << "Student".ljust(w) + "  Score  G  Missing"
rows.each do |s|
  if pct[s]
    r = r1(pct[s]); v = r / 10.0
    g = r >= 900 ? "A" : r >= 800 ? "B" : r >= 700 ? "C" : r >= 600 ? "D" : "F"
    sc = format("%5.1f", r / 10.0)
  else
    sc = "  n/a"; g = "-"
  end
  out << "#{s.ljust(w)}  #{sc}  #{g}  #{missing[s].to_s.rjust(7)}"
end
vals = pct.values.compact
out << "class average: " + (vals.empty? ? "n/a" : format("%.1f", r1(vals.sum / vals.size) / 10.0))
puts out

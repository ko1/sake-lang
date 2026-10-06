weights = {}
students = {} # name => {cat => [points, max]}
missing = Hash.new(0)

def tenths(r) = (r * 10 + Rational(1, 2)).floor

def tstr(t) = format("%d.%d", t / 10, t % 10)

$stdin.each_line.with_index(1) do |raw, no|
  line = raw.strip
  next if line.empty? || line.start_with?("#")
  f = line.split(/\s+/)
  if f[0] == "weight" && f.size == 3
    cat, w = f[1], f[2]
    if w !~ /\A\d+\z/ || !(1..100).cover?(w.to_i)
      puts "line #{no}: bad weight #{w}"
    elsif weights.key?(cat)
      puts "line #{no}: duplicate category #{cat}"
    else
      weights[cat] = w.to_i
    end
    next
  end
  if f.size != 3
    puts "line #{no}: bad format"
    next
  end
  st, cat, sc = f
  unless weights.key?(cat)
    puts "line #{no}: unknown category #{cat}"
    next
  end
  kind = nil
  p = 0
  m = 0
  if sc == "EX" then kind = :ex
  elsif sc == "-" then kind = :miss
  elsif (md = sc.match(%r{\A(EX|-|\d+)/(\d+)\z})) && md[2].to_i > 0 && (md[1] !~ /\A\d+\z/ || md[1].to_i <= md[2].to_i)
    m = md[2].to_i
    kind = md[1] == "EX" ? :ex : md[1] == "-" ? :miss : :pts
    p = md[1].to_i if kind == :pts
  else
    puts "line #{no}: bad score #{sc}"
    next
  end
  students[st] ||= {}
  next if kind == :ex
  missing[st] += 1 if kind == :miss
  c = (students[st][cat] ||= [0, 0])
  c[0] += p
  c[1] += m
end

w = [7, students.keys.map(&:size).max || 0].max
rows = students.map do |name, cats|
  num = 0
  den = 0
  cats.each do |cat, v|
    next if v[1] == 0
    num += weights[cat] * Rational(v[0], v[1])
    den += weights[cat]
  end
  [name, den == 0 ? nil : 100 * num / den, missing[name]]
end

puts "#{'Student'.ljust(w)}  Score  G  Missing"
with = rows.select { |r| r[1] }.map { |n, pct, ms| [n, pct, tenths(pct), ms] }
with.sort_by { |n, _, t, _| [-t, n.b] }.each do |n, _, t, ms|
  g = t >= 900 ? "A" : t >= 800 ? "B" : t >= 700 ? "C" : t >= 600 ? "D" : "F"
  puts "#{n.ljust(w)}  #{tstr(t).rjust(5)}  #{g}  #{ms.to_s.rjust(7)}"
end
rows.reject { |r| r[1] }.sort_by { |r| r[0].b }.each do |n, _, ms|
  puts "#{n.ljust(w)}  #{'n/a'.rjust(5)}  -  #{ms.to_s.rjust(7)}"
end
if with.empty?
  puts "class average: n/a"
else
  puts "class average: #{tstr(tenths(with.sum { |r| r[1] } / with.size))}"
end

def r1(x) # half up to one decimal, x Rational >= 0
  (x * 10 + Rational(1, 2)).floor
end
def fmt(t) = "#{t / 10}.#{t % 10}"

W = {}
errs = []
studs = {} # name => {cat => [pts, max]}, missing
miss = Hash.new(0)
$stdin.each_line.with_index(1) do |raw, n|
  l = raw.strip
  next if l.empty? || l.start_with?("#")
  f = l.split
  if f.size == 3 && f[0] == "weight"
    c, w = f[1], f[2]
    if w !~ /\A\d+\z/ || !(1..100).cover?(w.to_i)
      errs << "line #{n}: bad weight #{w}"
    elsif W.key?(c)
      errs << "line #{n}: duplicate category #{c}"
    else
      W[c] = w.to_i
    end
    next
  end
  if f.size != 3
    errs << "line #{n}: bad format"
    next
  end
  s, c, sc = f
  unless W.key?(c)
    errs << "line #{n}: unknown category #{c}"
    next
  end
  md = /\A(\d+|EX|-)\/(\d+)\z/.match(sc)
  unless md && md[2].to_i > 0 && (md[1] !~ /\d/ || md[1].to_i <= md[2].to_i)
    errs << "line #{n}: bad score #{sc}"
    next
  end
  pf, m = md[1], md[2].to_i
  studs[s] ||= {}
  next if pf == "EX"
  miss[s] += 1 if pf == "-"
  studs[s][c] ||= [0, 0]
  studs[s][c][0] += pf.to_i if pf != "-"
  studs[s][c][1] += m
end
puts errs
rows = []
sum = Rational(0)
cnt = 0
studs.each do |s, cats|
  tw = 0
  acc = Rational(0)
  cats.each do |c, (p, m)|
    next if m == 0
    tw += W[c]
    acc += Rational(W[c] * p, m)
  end
  if tw > 0
    pc = acc * 100 / tw
    sum += pc
    cnt += 1
    t = r1(pc)
    g = t >= 900 ? "A" : t >= 800 ? "B" : t >= 700 ? "C" : t >= 600 ? "D" : "F"
    rows << [s, t, g]
  else
    rows << [s, nil, "-"]
  end
end
w = [7, studs.keys.map(&:size).max || 0].max
puts "Student".ljust(w) + "  Score  G  Missing"
a = rows.select { |r| r[1] }.sort_by { |r| [-r[1], r[0]] }
b = rows.reject { |r| r[1] }.sort_by { |r| r[0] }
(a + b).each do |s, t, g|
  puts "#{s.ljust(w)}  #{(t ? fmt(t) : "n/a").rjust(5)}  #{g}  #{miss[s].to_s.rjust(7)}"
end
puts "class average: #{cnt > 0 ? fmt(r1(sum / cnt)) : "n/a"}"

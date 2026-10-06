NAME = /\A[A-Za-z][A-Za-z0-9_]{0,11}\z/
St = Struct.new(:p, :w, :d, :l, :gf, :ga)
teams = {}
games = []
$stdin.each_line.with_index(1) do |raw, n|
  line = raw.chomp
  line = line.chomp("\r") if line.end_with?("\r")
  f = line.split
  next if f.empty?
  ok = f.size == 3 && f[0] =~ NAME && f[2] =~ NAME && f[0] != f[2] &&
       (f[1] =~ /\A\d{1,2}-\d{1,2}\z/ || f[1] == "P-P")
  unless ok
    puts "invalid line #{n}: #{line}"
    next
  end
  h, s, a = f
  teams[h] ||= St.new(0, 0, 0, 0, 0, 0)
  teams[a] ||= St.new(0, 0, 0, 0, 0, 0)
  next if s == "P-P"
  hg, ag = s.split("-").map(&:to_i)
  games << [h, a, hg, ag]
  [[h, hg, ag], [a, ag, hg]].each do |t, gf, ga|
    x = teams[t]
    x.p += 1
    x.gf += gf
    x.ga += ga
    if gf > ga then x.w += 1
    elsif gf == ga then x.d += 1
    else x.l += 1
    end
  end
end
if teams.empty?
  puts "no teams"
  exit
end
pts = ->(x) { x.w * 3 + x.d }
base = teams.to_h { |k, x| [k, [-pts.(x), -(x.gf - x.ga), -x.gf]] }
groups = teams.keys.group_by { |k| base[k] }
h2h = Hash.new(0)
groups.each_value do |g|
  next if g.size < 2
  games.each do |h, a, hg, ag|
    next unless g.include?(h) && g.include?(a)
    if hg > ag then h2h[h] += 3
    elsif hg == ag
      h2h[h] += 1
      h2h[a] += 1
    else h2h[a] += 3
    end
  end
end
key = ->(k) { base[k] + [-h2h[k]] }
order = teams.keys.sort_by { |k| key.(k) + [k] }
fmt = "%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s"
puts format(fmt, "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")
order.each do |k|
  x = teams[k]
  pos = 1 + order.count { |o| (key.(o) <=> key.(k)) < 0 }
  gd = x.gf - x.ga
  gds = gd > 0 ? "+#{gd}" : gd.to_s
  puts format(fmt, pos, k, x.p, x.w, x.d, x.l, x.gf, x.ga, gds, pts.(x))
end

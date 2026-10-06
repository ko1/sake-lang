NAME = /\A[A-Za-z][A-Za-z0-9_]{0,11}\z/
teams = {}
games = []
St = Struct.new(:p, :w, :d, :l, :gf, :ga)

$stdin.each_line.with_index(1) do |raw, no|
  text = raw.chomp
  next if text.strip.empty?
  f = text.split(/\s+/).reject(&:empty?)
  ok = f.size == 3 && f[0] =~ NAME && f[2] =~ NAME && f[0] != f[2] &&
       (f[1] == "P-P" || f[1] =~ /\A\d{1,2}-\d{1,2}\z/)
  unless ok
    puts "invalid line #{no}: #{text}"
    next
  end
  h, s, a = f
  teams[h] ||= St.new(0, 0, 0, 0, 0, 0)
  teams[a] ||= St.new(0, 0, 0, 0, 0, 0)
  next if s == "P-P"
  hg, ag = s.split("-").map(&:to_i)
  games << [h, a, hg, ag]
  teams[h].p += 1
  teams[a].p += 1
  teams[h].gf += hg; teams[h].ga += ag
  teams[a].gf += ag; teams[a].ga += hg
  if hg > ag then teams[h].w += 1; teams[a].l += 1
  elsif hg < ag then teams[a].w += 1; teams[h].l += 1
  else teams[h].d += 1; teams[a].d += 1
  end
end

if teams.empty?
  puts "no teams"
  exit
end

pts = ->(t) { teams[t].w * 3 + teams[t].d }
gd = ->(t) { teams[t].gf - teams[t].ga }
base = ->(t) { [-pts.call(t), -gd.call(t), -teams[t].gf] }
h2h = Hash.new(0)
teams.keys.group_by { |t| base.call(t) }.each_value do |grp|
  next if grp.size < 2
  games.each do |h, a, hg, ag|
    next unless grp.include?(h) && grp.include?(a)
    if hg > ag then h2h[h] += 3
    elsif hg < ag then h2h[a] += 3
    else h2h[h] += 1; h2h[a] += 1
    end
  end
end
key = ->(t) { base.call(t) + [-h2h[t]] }
order = teams.keys.sort_by { |t| key.call(t) + [t.b] }

puts format("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s", "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")
order.each do |t|
  s = teams[t]
  pos = 1 + teams.keys.count { |u| (key.call(u) <=> key.call(t)) < 0 }
  g = gd.call(t)
  gs = g > 0 ? "+#{g}" : g.to_s
  puts format("%3d %-12s%3d%3d%3d%3d%4d%4d%4s%4d", pos, t, s.p, s.w, s.d, s.l, s.gf, s.ga, gs, pts.call(t))
end

NAME = /\A[A-Za-z][A-Za-z0-9_]{0,11}\z/
teams = {}
games = []
$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  next if line.strip.empty?
  tk = line.split
  ok = false
  if tk.size == 3 && tk[0] =~ NAME && tk[2] =~ NAME && tk[0] != tk[2]
    if tk[1] == "P-P"
      ok = true
      games << [tk[0], tk[2], nil, nil]
    elsif tk[1] =~ /\A(\d{1,2})-(\d{1,2})\z/
      ok = true
      games << [tk[0], tk[2], $1.to_i, $2.to_i]
    end
  end
  puts "invalid line #{no}: #{line}" unless ok
end
games.each do |g|
  [g[0], g[1]].each { |t| teams[t] ||= {p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0} }
end
if teams.empty?
  puts "no teams"
  exit
end
games.each do |h, a, hg, ag|
  next unless hg
  th = teams[h]; ta = teams[a]
  th[:p] += 1; ta[:p] += 1
  th[:gf] += hg; th[:ga] += ag; ta[:gf] += ag; ta[:ga] += hg
  if hg > ag
    th[:w] += 1; ta[:l] += 1; th[:pts] += 3
  elsif hg < ag
    ta[:w] += 1; th[:l] += 1; ta[:pts] += 3
  else
    th[:d] += 1; ta[:d] += 1; th[:pts] += 1; ta[:pts] += 1
  end
end
teams.each_value { |s| s[:gd] = s[:gf] - s[:ga] }
groups = teams.keys.group_by { |k| s = teams[k]; [s[:pts], s[:gd], s[:gf]] }
h2h = {}
groups.each_value do |mem|
  mem.each { |m| h2h[m] = 0 }
  games.each do |h, a, hg, ag|
    next unless hg && mem.include?(h) && mem.include?(a)
    if hg > ag then h2h[h] += 3
    elsif hg < ag then h2h[a] += 3
    else h2h[h] += 1; h2h[a] += 1
    end
  end
end
key = ->(k) { s = teams[k]; [-s[:pts], -s[:gd], -s[:gf], -h2h[k]] }
order = teams.keys.sort_by { |k| key.(k) + [k.b] }
puts format("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s", "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")
order.each do |k|
  s = teams[k]
  pos = 1 + order.count { |o| (key.(o) <=> key.(k)) < 0 }
  gd = s[:gd] > 0 ? "+#{s[:gd]}" : s[:gd].to_s
  puts format("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s", pos, k, s[:p], s[:w], s[:d], s[:l], s[:gf], s[:ga], gd, s[:pts])
end

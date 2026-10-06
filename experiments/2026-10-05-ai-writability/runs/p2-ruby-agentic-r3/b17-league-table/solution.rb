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
      games << [tk[0], tk[2], nil]
    elsif (m = tk[1].match(/\A(\d{1,2})-(\d{1,2})\z/))
      ok = true
      games << [tk[0], tk[2], [m[1].to_i, m[2].to_i]]
    end
  end
  puts "invalid line #{no}: #{line}" unless ok
end
if games.empty?
  puts "no teams"
  exit
end
games.each do |h, a, _|
  [h, a].each { |x| teams[x] ||= { name: x, p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0 } }
end
games.each do |h, a, s|
  next unless s
  hg, ag = s
  th = teams[h]; ta = teams[a]
  th[:p] += 1; ta[:p] += 1
  th[:gf] += hg; th[:ga] += ag
  ta[:gf] += ag; ta[:ga] += hg
  if hg > ag
    th[:w] += 1; th[:pts] += 3; ta[:l] += 1
  elsif hg < ag
    ta[:w] += 1; ta[:pts] += 3; th[:l] += 1
  else
    th[:d] += 1; ta[:d] += 1; th[:pts] += 1; ta[:pts] += 1
  end
end
list = teams.values
list.each { |t| t[:gd] = t[:gf] - t[:ga] }
groups = list.group_by { |t| [t[:pts], t[:gd], t[:gf]] }
list.each { |t| t[:h2h] = 0 }
groups.each_value do |g|
  names = g.map { |t| t[:name] }
  games.each do |h, a, s|
    next unless s && names.include?(h) && names.include?(a)
    hg, ag = s
    if hg > ag then teams[h][:h2h] += 3
    elsif hg < ag then teams[a][:h2h] += 3
    else teams[h][:h2h] += 1; teams[a][:h2h] += 1
    end
  end
end
key = ->(t) { [t[:pts], t[:gd], t[:gf], t[:h2h]] }
sorted = list.sort_by { |t| [-t[:pts], -t[:gd], -t[:gf], -t[:h2h], t[:name].b] }
fmt = "%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s"
puts format(fmt, "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")
sorted.each do |t|
  pos = 1 + list.count { |o| (key.(o) <=> key.(t)) == 1 }
  gd = t[:gd] > 0 ? "+#{t[:gd]}" : t[:gd].to_s
  puts format(fmt, pos, t[:name], t[:p], t[:w], t[:d], t[:l], t[:gf], t[:ga], gd, t[:pts])
end

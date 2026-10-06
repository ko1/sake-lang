NAME = /\A[A-Za-z][A-Za-z0-9_]{0,11}\z/
teams = {}
matches = []
$stdin.read.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  tk = line.split
  next if tk.empty?
  ok = false
  if tk.size == 3 && tk[0] =~ NAME && tk[2] =~ NAME && tk[0] != tk[2]
    if tk[1] == "P-P"
      ok = true
      post = true
    elsif (m = /\A(\d{1,2})-(\d{1,2})\z/.match(tk[1]))
      ok = true
      post = false
    end
  end
  unless ok
    puts "invalid line #{no}: #{line}"
    next
  end
  h, a = tk[0], tk[2]
  [h, a].each { |x| teams[x] ||= { n: x, p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0 } }
  next if post
  hg, ag = m[1].to_i, m[2].to_i
  matches << [h, a, hg, ag]
  { h => [hg, ag], a => [ag, hg] }.each do |nm, (gf, ga)|
    t = teams[nm]
    t[:p] += 1
    t[:gf] += gf
    t[:ga] += ga
    if gf > ga
      t[:w] += 1
      t[:pts] += 3
    elsif gf == ga
      t[:d] += 1
      t[:pts] += 1
    else
      t[:l] += 1
    end
  end
end
if teams.empty?
  puts "no teams"
  exit
end
list = teams.values
list.each { |t| t[:gd] = t[:gf] - t[:ga]; t[:h2h] = 0 }
groups = list.group_by { |t| [t[:pts], t[:gd], t[:gf]] }
groups.each_value do |g|
  next if g.size < 2
  names = g.map { |t| t[:n] }
  matches.each do |h, a, hg, ag|
    next unless names.include?(h) && names.include?(a)
    if hg > ag
      teams[h][:h2h] += 3
    elsif hg < ag
      teams[a][:h2h] += 3
    else
      teams[h][:h2h] += 1
      teams[a][:h2h] += 1
    end
  end
end
key = ->(t) { [-t[:pts], -t[:gd], -t[:gf], -t[:h2h]] }
list.sort_by! { |t| key.(t) + [t[:n]] }
puts format("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s", "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")
list.each do |t|
  pos = 1 + list.count { |o| (key.(o) <=> key.(t)) < 0 }
  gd = t[:gd] > 0 ? "+#{t[:gd]}" : t[:gd].to_s
  puts format("%3d %-12s%3d%3d%3d%3d%4d%4d%4s%4d", pos, t[:n], t[:p], t[:w], t[:d], t[:l], t[:gf], t[:ga], gd, t[:pts])
end

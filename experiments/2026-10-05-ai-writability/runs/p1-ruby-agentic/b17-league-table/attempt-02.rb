NAME = /\A[A-Za-z][A-Za-z0-9_]{0,11}\z/n
SC = /\A(\d{1,2})-(\d{1,2})\z/n
teams = {}
games = []
$stdin.binmode.read.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  w = line.split
  next if w.empty?
  ok = w.size == 3 && w[0] =~ NAME && w[2] =~ NAME && w[0] != w[2] &&
       (w[1] == "P-P" || w[1] =~ SC)
  unless ok
    puts "invalid line #{no}: #{line}".b
    next
  end
  h, s, a = w
  [h, a].each { |t| teams[t] ||= { p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0 } }
  next if s == "P-P"
  gh, ga = s.split("-").map(&:to_i)
  games << [h, a, gh, ga]
  { h => [gh, ga], a => [ga, gh] }.each do |t, (f, g)|
    x = teams[t]
    x[:p] += 1; x[:gf] += f; x[:ga] += g
    if f > g then x[:w] += 1; x[:pts] += 3
    elsif f == g then x[:d] += 1; x[:pts] += 1
    else x[:l] += 1
    end
  end
end
if teams.empty?
  puts "no teams"; exit
end
teams.each_value { |x| x[:gd] = x[:gf] - x[:ga]; x[:h2h] = 0 }
groups = teams.keys.group_by { |t| x = teams[t]; [x[:pts], x[:gd], x[:gf]] }
groups.each_value do |g|
  next if g.size < 2
  games.each do |h, a, gh, ga|
    next unless g.include?(h) && g.include?(a)
    if gh > ga then teams[h][:h2h] += 3
    elsif gh == ga then teams[h][:h2h] += 1; teams[a][:h2h] += 1
    else teams[a][:h2h] += 3
    end
  end
end
key = ->(t) { x = teams[t]; [-x[:pts], -x[:gd], -x[:gf], -x[:h2h]] }
order = teams.keys.sort_by { |t| key.(t) + [t.b] }
fmt = "%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s"
puts format(fmt, "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")
order.each_with_index do |t, i|
  x = teams[t]
  pos = 1 + order.count { |u| (key.(u) <=> key.(t)) < 0 }
  gd = x[:gd] > 0 ? "+#{x[:gd]}" : x[:gd].to_s
  puts format(fmt, pos, t, x[:p], x[:w], x[:d], x[:l], x[:gf], x[:ga], gd, x[:pts])
end

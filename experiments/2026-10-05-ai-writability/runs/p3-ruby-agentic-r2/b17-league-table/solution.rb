NAME = /\A[A-Za-z][A-Za-z0-9_]{0,11}\z/
teams = {}
matches = []
$stdin.read.split("\n").each_with_index do |raw, i|
  ln = raw.chomp("\r")
  next if ln.strip.empty?
  t = ln.split
  ok = t.size == 3 && t[0] =~ NAME && t[2] =~ NAME && t[0] != t[2] &&
       (t[1] =~ /\A\d{1,2}-\d{1,2}\z/ || t[1] == "P-P")
  unless ok
    puts "invalid line #{i + 1}: #{ln}"
    next
  end
  h, s, a = t
  teams[h] ||= { p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0 }
  teams[a] ||= { p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0 }
  next if s == "P-P"
  hg, ag = s.split("-").map(&:to_i)
  matches << [h, a, hg, ag]
  [[h, hg, ag], [a, ag, hg]].each do |n, gf, ga|
    x = teams[n]
    x[:p] += 1; x[:gf] += gf; x[:ga] += ga
    if gf > ga then x[:w] += 1; x[:pts] += 3
    elsif gf == ga then x[:d] += 1; x[:pts] += 1
    else x[:l] += 1
    end
  end
end
if teams.empty?
  puts "no teams"; exit
end
teams.each_value { |x| x[:gd] = x[:gf] - x[:ga] }
groups = teams.keys.group_by { |n| x = teams[n]; [x[:pts], x[:gd], x[:gf]] }
groups.each_value do |g|
  g.each { |n| teams[n][:h2h] = 0 }
  next if g.size < 2
  matches.each do |h, a, hg, ag|
    next unless g.include?(h) && g.include?(a)
    if hg > ag then teams[h][:h2h] += 3
    elsif hg < ag then teams[a][:h2h] += 3
    else teams[h][:h2h] += 1; teams[a][:h2h] += 1
    end
  end
end
key = ->(n) { x = teams[n]; [-x[:pts], -x[:gd], -x[:gf], -x[:h2h]] }
order = teams.keys.sort_by { |n| key.(n) + [n.b] }
puts format("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s", "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")
order.each_with_index do |n, i|
  x = teams[n]
  pos = 1 + order.count { |m| (key.(m) <=> key.(n)) < 0 }
  gd = x[:gd] > 0 ? "+#{x[:gd]}" : x[:gd].to_s
  puts format("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s", pos, n, x[:p], x[:w], x[:d], x[:l], x[:gf], x[:ga], gd, x[:pts])
end

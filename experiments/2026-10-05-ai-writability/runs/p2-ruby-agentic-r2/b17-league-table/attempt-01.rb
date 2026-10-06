NAME = /\A[A-Za-z][A-Za-z0-9_]{0,11}\z/
teams = {}
games = []
STDIN.each_line.with_index(1) do |raw, n|
  line = raw.chomp
  next if line.strip.empty?
  tk = line.split
  ok = tk.size == 3 && tk[0] =~ NAME && tk[2] =~ NAME && tk[0] != tk[2] &&
       (tk[1] == "P-P" || tk[1] =~ /\A\d{1,2}-\d{1,2}\z/)
  unless ok
    puts "invalid line #{n}: #{line}"
    next
  end
  [tk[0], tk[2]].each { |t| teams[t] ||= { name: t, w: 0, d: 0, l: 0, gf: 0, ga: 0 } }
  next if tk[1] == "P-P"
  h, a = tk[1].split("-").map(&:to_i)
  games << [tk[0], tk[2], h, a]
  hh = teams[tk[0]]; aa = teams[tk[2]]
  hh[:gf] += h; hh[:ga] += a; aa[:gf] += a; aa[:ga] += h
  if h > a then hh[:w] += 1; aa[:l] += 1
  elsif h < a then aa[:w] += 1; hh[:l] += 1
  else hh[:d] += 1; aa[:d] += 1
  end
end
if teams.empty?
  puts "no teams"
  exit
end
teams.each_value do |t|
  t[:pts] = 3 * t[:w] + t[:d]
  t[:gd] = t[:gf] - t[:ga]
  t[:p] = t[:w] + t[:d] + t[:l]
end
key = ->(t) { [-t[:pts], -t[:gd], -t[:gf]] }
groups = teams.values.group_by(&key)
groups.each_value do |g|
  names = g.map { |t| t[:name] }
  g.each { |t| t[:h2h] = 0 }
  games.each do |hn, an, h, a|
    next unless names.include?(hn) && names.include?(an)
    if h > a then teams[hn][:h2h] += 3
    elsif h < a then teams[an][:h2h] += 3
    else teams[hn][:h2h] += 1; teams[an][:h2h] += 1
    end
  end
end
list = teams.values.sort_by { |t| [-t[:pts], -t[:gd], -t[:gf], -t[:h2h], t[:name].b] }
fmt = "%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s"
puts format(fmt, "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")
list.each_with_index do |t, i|
  k = ->(x) { [x[:pts], x[:gd], x[:gf], x[:h2h]] }
  pos = 1 + list.count { |o| (k.(o) <=> k.(t)) == 1 }
  gd = t[:gd] > 0 ? "+#{t[:gd]}" : t[:gd].to_s
  puts format(fmt, pos, t[:name], t[:p], t[:w], t[:d], t[:l], t[:gf], t[:ga], gd, t[:pts])
end

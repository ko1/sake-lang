data = $stdin.read.to_s.b
lines = data.split("\n", -1)
lines.pop if lines.last == ""
name_re = /\A[A-Za-z][A-Za-z0-9_]{0,11}\z/n
score_re = /\A([0-9]{1,2})-([0-9]{1,2})\z/n
teams = {}
games = []
lines.each_with_index do |raw, i|
  line = raw.chomp("\r")
  next if line.match?(/\A[ \t\r\f\v]*\z/n)
  tk = line.split(/[ \t\r\f\v]+/n).reject(&:empty?)
  ok = tk.size == 3 && tk[0].match?(name_re) && tk[2].match?(name_re) && tk[0] != tk[2]
  post = false
  m = nil
  if ok
    if tk[1] == "P-P"
      post = true
    else
      m = score_re.match(tk[1])
      ok = !m.nil?
    end
  end
  unless ok
    puts "invalid line #{i + 1}: #{line}"
    next
  end
  h, a = tk[0], tk[2]
  [h, a].each { |x| teams[x] ||= { name: x, p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0 } }
  next if post
  hg = m[1].to_i
  ag = m[2].to_i
  games << [h, a, hg, ag]
  { h => [hg, ag], a => [ag, hg] }.each do |x, (gf, ga)|
    t = teams[x]
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
list.each { |t| t[:gd] = t[:gf] - t[:ga] }
groups = list.group_by { |t| [t[:pts], t[:gd], t[:gf]] }
groups.each_value do |g|
  names = g.map { |t| t[:name] }
  g.each { |t| t[:h2h] = 0 }
  next if g.size < 2
  by = g.to_h { |t| [t[:name], t] }
  games.each do |h, a, hg, ag|
    next unless names.include?(h) && names.include?(a)
    if hg > ag
      by[h][:h2h] += 3
    elsif hg == ag
      by[h][:h2h] += 1
      by[a][:h2h] += 1
    else
      by[a][:h2h] += 3
    end
  end
end
key = ->(t) { [-t[:pts], -t[:gd], -t[:gf], -t[:h2h]] }
list.sort_by! { |t| key.(t) + [t[:name]] }
puts format("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s", "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")
list.each do |t|
  k = key.(t)
  pos = 1 + list.count { |u| (key.(u) <=> k) < 0 }
  gd = t[:gd] > 0 ? "+#{t[:gd]}" : t[:gd].to_s
  puts format("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s", pos, t[:name], t[:p], t[:w], t[:d], t[:l], t[:gf], t[:ga], gd, t[:pts])
end

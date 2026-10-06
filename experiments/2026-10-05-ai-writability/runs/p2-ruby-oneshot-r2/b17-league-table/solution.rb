NAME = /\A[A-Za-z][A-Za-z0-9_]{0,11}\z/
teams = {}
matches = []
$stdin.readlines.map(&:chomp).each_with_index do |ln, i|
  next if ln.strip.empty?
  tk = ln.split
  ok = tk.size == 3 && tk[0].match?(NAME) && tk[2].match?(NAME) && tk[0] != tk[2] &&
       (tk[1] == "P-P" || tk[1].match?(/\A\d{1,2}-\d{1,2}\z/))
  unless ok
    puts "invalid line #{i + 1}: #{ln}"
    next
  end
  hm, sc, aw = tk
  [hm, aw].each { |x| teams[x] ||= { w: 0, d: 0, l: 0, gf: 0, ga: 0 } }
  next if sc == "P-P"
  hg, ag = sc.split("-").map(&:to_i)
  matches << [hm, aw, hg, ag]
  a = teams[hm]
  b = teams[aw]
  a[:gf] += hg; a[:ga] += ag
  b[:gf] += ag; b[:ga] += hg
  if hg > ag
    a[:w] += 1; b[:l] += 1
  elsif hg < ag
    a[:l] += 1; b[:w] += 1
  else
    a[:d] += 1; b[:d] += 1
  end
end

if teams.empty?
  puts "no teams"
  exit
end

teams.each_value do |s|
  s[:pts] = s[:w] * 3 + s[:d]
  s[:gd] = s[:gf] - s[:ga]
end
groups = teams.keys.group_by { |k| [teams[k][:pts], teams[k][:gd], teams[k][:gf]] }
h2h = Hash.new(0)
groups.each_value do |mem|
  next if mem.size < 2
  matches.each do |hm, aw, hg, ag|
    next unless mem.include?(hm) && mem.include?(aw)
    if hg > ag
      h2h[hm] += 3
    elsif hg < ag
      h2h[aw] += 3
    else
      h2h[hm] += 1
      h2h[aw] += 1
    end
  end
end
key = ->(k) { [-teams[k][:pts], -teams[k][:gd], -teams[k][:gf], -h2h[k]] }
order = teams.keys.sort_by { |k| key.(k) + [k] }
fmt = "%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s"
puts format(fmt, "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")
order.each do |k|
  s = teams[k]
  pos = 1 + order.count { |o| (key.(o) <=> key.(k)) < 0 }
  gd = s[:gd] > 0 ? "+#{s[:gd]}" : s[:gd].to_s
  puts format(fmt, pos, k, s[:w] + s[:d] + s[:l], s[:w], s[:d], s[:l], s[:gf], s[:ga], gd, s[:pts])
end

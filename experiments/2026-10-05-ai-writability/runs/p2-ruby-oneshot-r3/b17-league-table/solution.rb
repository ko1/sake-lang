NAME = /\A[A-Za-z][A-Za-z0-9_]{0,11}\z/
teams = {}
matches = []
$stdin.read.each_line.with_index(1) do |raw, n|
  line = raw.chomp
  line = line.chomp("\r")
  next if line.strip.empty?
  tk = line.split
  ok = false
  if tk.size == 3 && tk[0] =~ NAME && tk[2] =~ NAME && tk[0] != tk[2]
    if tk[1] == "P-P"
      ok = true
      played = false
    elsif (m = /\A(\d{1,2})-(\d{1,2})\z/.match(tk[1]))
      ok = true
      played = true
      hg = m[1].to_i
      ag = m[2].to_i
    end
  end
  unless ok
    puts "invalid line #{n}: #{line}"
    next
  end
  teams[tk[0]] = true
  teams[tk[2]] = true
  matches << [tk[0], tk[2], hg, ag] if played
end
if teams.empty?
  puts "no teams"
  exit
end
st = {}
teams.each_key { |t| st[t] = { p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0 } }
matches.each do |h, a, hg, ag|
  [[h, hg, ag], [a, ag, hg]].each do |t, f, g|
    s = st[t]
    s[:p] += 1
    s[:gf] += f
    s[:ga] += g
    if f > g
      s[:w] += 1
      s[:pts] += 3
    elsif f == g
      s[:d] += 1
      s[:pts] += 1
    else
      s[:l] += 1
    end
  end
end
groups = Hash.new { |hh, k| hh[k] = [] }
st.each { |t, s| groups[[s[:pts], s[:gf] - s[:ga], s[:gf]]] << t }
h2h = Hash.new(0)
groups.each_value do |members|
  next if members.size < 2
  matches.each do |h, a, hg, ag|
    next unless members.include?(h) && members.include?(a)
    if hg > ag
      h2h[h] += 3
    elsif hg == ag
      h2h[h] += 1
      h2h[a] += 1
    else
      h2h[a] += 3
    end
  end
end
key = {}
st.each { |t, s| key[t] = [-s[:pts], -(s[:gf] - s[:ga]), -s[:gf], -h2h[t]] }
order = st.keys.sort_by { |t| key[t] + [t] }
puts format("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s", "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")
order.each do |t|
  s = st[t]
  pos = 1 + order.count { |u| (key[u] <=> key[t]) < 0 }
  gd = s[:gf] - s[:ga]
  gds = gd > 0 ? "+#{gd}" : gd.to_s
  puts format("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s", pos, t, s[:p], s[:w], s[:d], s[:l], s[:gf], s[:ga], gds, s[:pts])
end

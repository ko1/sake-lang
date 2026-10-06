NAME_RE = /\A[A-Za-z][A-Za-z0-9_]{0,11}\z/
matches = []
teams = {}
$stdin.read.split("\n", -1).each_with_index do |raw, i|
  ln = raw.chomp
  next if ln.strip.empty?
  tk = ln.split
  ok = tk.size == 3 && tk[0] =~ NAME_RE && tk[2] =~ NAME_RE && tk[0] != tk[2] &&
       (tk[1] =~ /\A\d{1,2}-\d{1,2}\z/ || tk[1] == "P-P")
  unless ok
    puts "invalid line #{i + 1}: #{ln}"
    next
  end
  teams[tk[0]] = true
  teams[tk[2]] = true
  next if tk[1] == "P-P"
  a, b = tk[1].split("-").map(&:to_i)
  matches << [tk[0], tk[2], a, b]
end
if teams.empty?
  puts "no teams"
  exit
end
st = {}
teams.each_key { |n| st[n] = { p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0 } }
matches.each do |h, a, gh, ga|
  [[h, gh, ga], [a, ga, gh]].each do |n, f, g|
    s = st[n]
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
st.each { |n, s| groups[[s[:pts], s[:gd] = s[:gf] - s[:ga], s[:gf]]] << n }
h2h = Hash.new(0)
groups.each_value do |g|
  next if g.size < 2
  matches.each do |h, a, gh, ga|
    next unless g.include?(h) && g.include?(a)
    if gh > ga
      h2h[h] += 3
    elsif gh == ga
      h2h[h] += 1
      h2h[a] += 1
    else
      h2h[a] += 3
    end
  end
end
key = ->(n) { s = st[n]; [-s[:pts], -s[:gd], -s[:gf], -h2h[n]] }
order = st.keys.sort_by { |n| key.(n) + [n] }
puts format("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s", "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")
order.each do |n|
  s = st[n]
  pos = 1 + order.count { |o| (key.(o) <=> key.(n)) < 0 }
  gd = s[:gd] > 0 ? "+#{s[:gd]}" : s[:gd].to_s
  puts format("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s", pos, n, s[:p], s[:w], s[:d], s[:l], s[:gf], s[:ga], gd, s[:pts])
end

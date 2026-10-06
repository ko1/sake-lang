lines = $stdin.readlines.map(&:chomp)
h = (lines[0] || "").split
ok = h.size == 3 && h.all? { |x| x.match?(/\A\d+\z/) }
if ok
  n, d, c = h.map(&:to_i)
  ok = n.between?(2, 50) && d.between?(0, 5) && c.between?(1, 20)
end
unless ok
  puts "invalid header"
  exit
end

reqs = []
bad = []
prev = nil
(lines[1..] || []).each_with_index do |ln, i|
  num = i + 2
  next if ln.strip.empty?
  tk = ln.split
  valid = tk.size == 3 && tk.all? { |x| x.match?(/\A\d+\z/) }
  if valid
    t, f, g = tk.map(&:to_i)
    valid = t <= 1000 && f.between?(1, n) && g.between?(1, n) && f != g && (prev.nil? || t >= prev)
  end
  if valid
    reqs << [t, f, g]
    prev = t
  else
    bad << "line #{num}: invalid request"
  end
end
bad.each { |s| puts s }
if reqs.empty?
  puts "no passengers"
  exit
end

total = reqs.size
t = 0
f = 1
dir = 0
nxt = 0
waiting = []
riders = []
pick = Array.new(total)
drop = Array.new(total)
dropped = 0
last_drop = 0
while dropped < total
  while nxt < total && reqs[nxt][0] <= t
    waiting << nxt
    nxt += 1
  end
  offs = riders.select { |i| reqs[i][2] == f }.sort
  riders -= offs
  offs.each do |i|
    drop[i] = t
    last_drop = t
    puts "t=#{t} floor #{f} drop P#{i + 1}"
  end
  dropped += offs.size

  targets = riders.map { |i| reqs[i][2] } + waiting.map { |i| reqs[i][1] }
  above = targets.any? { |x| x > f }
  below = targets.any? { |x| x < f }
  if dir == 1
    dir = above ? 1 : (below ? -1 : 0)
  elsif dir == -1
    dir = below ? -1 : (above ? 1 : 0)
  end
  if dir == 0 && !targets.empty?
    near = targets.min_by { |x| [(x - f).abs, x] }
    if near > f
      dir = 1
    elsif near < f
      dir = -1
    else
      k = waiting.select { |i| reqs[i][1] == f }.min
      dir = reqs[k][2] > f ? 1 : -1
    end
  end

  ons = []
  if dir != 0
    cand = waiting.select { |i| reqs[i][1] == f && (reqs[i][2] > f ? 1 : -1) == dir }.sort
    cand.each do |i|
      break if riders.size + ons.size >= c
      ons << i
    end
  end
  waiting -= ons
  riders += ons
  ons.each do |i|
    pick[i] = t
    puts "t=#{t} floor #{f} pick P#{i + 1}"
  end

  if !offs.empty? || !ons.empty?
    t += d
  else
    f += dir
    t += 1
  end
end

sw = 0
sr = 0
total.times do |i|
  w = pick[i] - reqs[i][0]
  r = drop[i] - pick[i]
  sw += w
  sr += r
  puts "P#{i + 1} wait #{w} ride #{r}"
end
puts format("average wait %.2f ride %.2f", sw.to_f / total, sr.to_f / total)
puts "done at t=#{last_drop}"

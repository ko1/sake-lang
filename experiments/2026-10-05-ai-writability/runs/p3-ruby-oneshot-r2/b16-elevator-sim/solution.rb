lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
lines = lines.map { |l| l.chomp("\r") }
hdr = (lines[0] || "").split
ok = hdr.size == 3 && hdr.all? { |x| x =~ /\A\d+\z/ }
if ok
  n, d, c = hdr.map(&:to_i)
  ok = n.between?(2, 50) && d.between?(0, 5) && c.between?(1, 20)
end
unless ok
  puts "invalid header"
  exit
end
pass = []
prev = -1
lines.each_with_index do |l, i|
  next if i == 0
  tk = l.split
  next if tk.empty?
  valid = tk.size == 3 && tk.all? { |x| x =~ /\A\d+\z/ }
  if valid
    t, f, g = tk.map(&:to_i)
    valid = t <= 1000 && f.between?(1, n) && g.between?(1, n) && f != g && t >= prev
  end
  if valid
    pass << { t: t, f: f, g: g }
    prev = t
  else
    puts "line #{i + 1}: invalid request"
  end
end
if pass.empty?
  puts "no passengers"
  exit
end
m = pass.size
pass.each_with_index { |p, i| p[:i] = i }
t = 0
f = 1
dir = :idle
nxt = 0
waiting = []
riders = []
dropped = 0
while dropped < m
  while nxt < m && pass[nxt][:t] <= t
    waiting << pass[nxt]
    nxt += 1
  end
  off = riders.select { |p| p[:g] == f }.sort_by { |p| p[:i] }
  off.each do |p|
    p[:drop] = t
    puts "t=#{t} floor #{f} drop P#{p[:i] + 1}"
  end
  riders -= off
  dropped += off.size
  targets = riders.map { |p| p[:g] } + waiting.map { |p| p[:f] }
  case dir
  when :up
    dir = targets.any? { |x| x > f } ? :up : (targets.any? { |x| x < f } ? :down : :idle)
  when :down
    dir = targets.any? { |x| x < f } ? :down : (targets.any? { |x| x > f } ? :up : :idle)
  end
  if dir == :idle && !targets.empty?
    best = targets.min_by { |x| [(x - f).abs, x] }
    if best > f
      dir = :up
    elsif best < f
      dir = :down
    else
      p0 = waiting.select { |p| p[:f] == f }.min_by { |p| p[:i] }
      dir = p0[:g] > f ? :up : :down
    end
  end
  boarded = 0
  if dir != :idle
    cand = waiting.select { |p| p[:f] == f && ((p[:g] > f ? :up : :down) == dir) }.sort_by { |p| p[:i] }
    cand.each do |p|
      break if riders.size >= c
      p[:pick] = t
      puts "t=#{t} floor #{f} pick P#{p[:i] + 1}"
      riders << p
      waiting.delete(p)
      boarded += 1
    end
  end
  if !off.empty? || boarded > 0
    t += d
  else
    if dir == :up
      f += 1
    elsif dir == :down
      f -= 1
    end
    t += 1
  end
end
sw = 0
sr = 0
pass.each do |p|
  w = p[:pick] - p[:t]
  r = p[:drop] - p[:pick]
  sw += w
  sr += r
  puts "P#{p[:i] + 1} wait #{w} ride #{r}"
end
puts format("average wait %.2f ride %.2f", sw.to_f / m, sr.to_f / m)
puts "done at t=#{pass.map { |p| p[:drop] }.max}"

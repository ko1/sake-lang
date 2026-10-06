lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
hdr = (lines[0] || "").split
unless hdr.size == 3 && hdr.all? { |x| x =~ /\A\d+\z/ }
  puts "invalid header"; exit
end
n, d, c = hdr.map(&:to_i)
unless n.between?(2, 50) && d.between?(0, 5) && c.between?(1, 20)
  puts "invalid header"; exit
end
ps = []
prevT = nil
lines[1..].each_with_index do |ln, i|
  k = i + 2
  next if ln.strip.empty?
  t = ln.split
  ok = t.size == 3 && t.all? { |x| x =~ /\A\d+\z/ }
  if ok
    tt, f, g = t.map(&:to_i)
    ok = f.between?(1, n) && g.between?(1, n) && f != g && tt <= 1000 && (prevT.nil? || tt >= prevT)
  end
  if ok
    prevT = tt
    ps << { t: tt, f: f, g: g, pick: nil, drop: nil }
  else
    puts "line #{k}: invalid request"
  end
end
if ps.empty?
  puts "no passengers"; exit
end
f = 1; t = 0; dir = :idle
riders = []
waiting = []
started = 0
dropped = 0
last = 0
while dropped < ps.size
  while started < ps.size && ps[started][:t] <= t
    waiting << started; started += 1
  end
  off = riders.select { |i| ps[i][:g] == f }
  off.each do |i|
    puts "t=#{t} floor #{f} drop P#{i + 1}"
    ps[i][:drop] = t; last = t; dropped += 1
  end
  riders -= off
  targets = riders.map { |i| ps[i][:g] } + waiting.map { |i| ps[i][:f] }
  above = targets.any? { |x| x > f }
  below = targets.any? { |x| x < f }
  case dir
  when :up then dir = above ? :up : (below ? :down : :idle)
  when :down then dir = below ? :down : (above ? :up : :idle)
  end
  if dir == :idle && !targets.empty?
    best = targets.min_by { |x| [(x - f).abs, x] }
    if best > f then dir = :up
    elsif best < f then dir = :down
    else
      i = waiting.select { |w| ps[w][:f] == f }.min
      dir = ps[i][:g] > f ? :up : :down
    end
  end
  on = []
  waiting.sort.each do |i|
    next unless ps[i][:f] == f
    break if riders.size + on.size >= c
    pd = ps[i][:g] > f ? :up : :down
    on << i if pd == dir
  end
  on.each do |i|
    puts "t=#{t} floor #{f} pick P#{i + 1}"
    ps[i][:pick] = t
  end
  riders += on
  waiting -= on
  if !off.empty? || !on.empty?
    t += d
  else
    f += 1 if dir == :up
    f -= 1 if dir == :down
    t += 1
  end
end
ps.each_with_index { |p, i| puts "P#{i + 1} wait #{p[:pick] - p[:t]} ride #{p[:drop] - p[:pick]}" }
w = ps.sum { |p| p[:pick] - p[:t] }.to_f / ps.size
r = ps.sum { |p| p[:drop] - p[:pick] }.to_f / ps.size
puts format("average wait %.2f ride %.2f", w, r)
puts "done at t=#{last}"

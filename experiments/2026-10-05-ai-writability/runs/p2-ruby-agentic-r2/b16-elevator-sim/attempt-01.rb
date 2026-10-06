lines = STDIN.read.split("\n", -1)
lines.pop if lines.last == ""
def ints(l)
  w = l.split
  return nil unless w.size == 3 && w.all? { |x| x =~ /\A\d+\z/ }
  w.map(&:to_i)
end
h = lines[0] ? ints(lines[0]) : nil
if h.nil? || !(2..50).cover?(h[0]) || !(0..5).cover?(h[1]) || !(1..20).cover?(h[2])
  puts "invalid header"
  exit
end
n, d, cap = h
ps = []
prev = -1
(1...lines.size).each do |i|
  l = lines[i]
  next if l.strip.empty?
  r = ints(l)
  ok = r && r[0] <= 1000 && r[1].between?(1, n) && r[2].between?(1, n) && r[1] != r[2] && r[0] >= prev
  if ok
    prev = r[0]
    ps << { t: r[0], f: r[1], g: r[2] }
  else
    puts "line #{i + 1}: invalid request"
  end
end
if ps.empty?
  puts "no passengers"
  exit
end
ps.each_with_index { |p, i| p[:id] = i + 1 }
f = 1; t = 0; dir = :idle
waiting = []; riding = []; pending = ps.dup; dropped = 0
while dropped < ps.size
  while pending.first && pending.first[:t] <= t
    waiting << pending.shift
  end
  changed = false
  off = riding.select { |p| p[:g] == f }
  off.each do |p|
    puts "t=#{t} floor #{f} drop P#{p[:id]}"
    p[:drop] = t
    dropped += 1
    changed = true
  end
  riding -= off
  targets = riding.map { |p| p[:g] } + waiting.map { |p| p[:f] }
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
      p0 = waiting.select { |p| p[:f] == f }.min_by { |p| p[:id] }
      dir = p0[:g] > f ? :up : :down
    end
  end
  cands = waiting.select { |p| p[:f] == f && (p[:g] > f ? :up : :down) == dir }.sort_by { |p| p[:id] }
  cands.each do |p|
    break unless riding.size < cap
    puts "t=#{t} floor #{f} pick P#{p[:id]}"
    p[:pick] = t
    riding << p
    waiting.delete(p)
    changed = true
  end
  if changed
    t += d
  else
    f += 1 if dir == :up
    f -= 1 if dir == :down
    t += 1
  end
end
ps.each { |p| puts "P#{p[:id]} wait #{p[:pick] - p[:t]} ride #{p[:drop] - p[:pick]}" }
w = ps.sum { |p| p[:pick] - p[:t] }.to_f / ps.size
r = ps.sum { |p| p[:drop] - p[:pick] }.to_f / ps.size
puts format("average wait %.2f ride %.2f", w, r)
puts "done at t=#{ps.map { |p| p[:drop] }.max}"

lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
head = (lines[0] || "").split
dig = ->(s) { s =~ /\A\d+\z/ }
unless head.size == 3 && head.all?(&dig)
  puts "invalid header"; exit
end
n, d, c = head.map(&:to_i)
unless (2..50).cover?(n) && (0..5).cover?(d) && (1..20).cover?(c)
  puts "invalid header"; exit
end
ps = []
prev = 0
errs = []
lines[1..].to_a.each_with_index do |ln, i|
  k = i + 2
  next if ln.strip.empty?
  w = ln.split
  ok = w.size == 3 && w.all?(&dig)
  if ok
    t, f, g = w.map(&:to_i)
    ok = (1..n).cover?(f) && (1..n).cover?(g) && f != g && t <= 1000 && t >= prev
  end
  if ok
    ps << { t: t, f: f, g: g, pick: nil, drop: nil }
    prev = t
  else
    errs << "line #{k}: invalid request"
  end
end
puts errs
if ps.empty?
  puts "no passengers"; exit
end
t = 0; f = 1; dir = :idle
waiting = []; riding = []; started = 0; dropped = 0
out = []
while dropped < ps.size
  while started < ps.size && ps[started][:t] <= t
    waiting << started; started += 1
  end
  acted = false
  off = riding.select { |i| ps[i][:g] == f }.sort
  off.each { |i| out << "t=#{t} floor #{f} drop P#{i + 1}"; ps[i][:drop] = t; riding.delete(i); dropped += 1; acted = true }
  targets = riding.map { |i| ps[i][:g] } + waiting.map { |i| ps[i][:f] }
  up = targets.any? { |x| x > f }
  down = targets.any? { |x| x < f }
  case dir
  when :up then dir = up ? :up : (down ? :down : :idle)
  when :down then dir = down ? :down : (up ? :up : :idle)
  end
  if dir == :idle && !targets.empty?
    best = targets.min_by { |x| [(x - f).abs, x] }
    if best > f then dir = :up
    elsif best < f then dir = :down
    else
      i = waiting.select { |j| ps[j][:f] == f }.min
      dir = ps[i][:g] > f ? :up : :down
    end
  end
  ons = waiting.select { |i| ps[i][:f] == f && (ps[i][:g] > f ? :up : :down) == dir }.sort
  ons.each do |i|
    break unless riding.size < c
    out << "t=#{t} floor #{f} pick P#{i + 1}"; ps[i][:pick] = t
    waiting.delete(i); riding << i; acted = true
  end
  if acted
    t += d
  else
    f += 1 if dir == :up
    f -= 1 if dir == :down
    t += 1
  end
end
puts out
ps.each_with_index { |p, i| puts "P#{i + 1} wait #{p[:pick] - p[:t]} ride #{p[:drop] - p[:pick]}" }
w = ps.sum { |p| p[:pick] - p[:t] }.to_f / ps.size
r = ps.sum { |p| p[:drop] - p[:pick] }.to_f / ps.size
puts format("average wait %.2f ride %.2f", w, r)
puts "done at t=#{ps.map { |p| p[:drop] }.max}"

lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
lines = lines.map { |l| l.chomp("\r") }
def ints(s)
  t = s.split
  return nil unless t.all? { |x| x =~ /\A\d+\z/ }
  t.map(&:to_i)
end
h = ints(lines[0] || "")
unless h && h.size == 3 && h[0] >= 2 && h[0] <= 50 && h[1] >= 0 && h[1] <= 5 && h[2] >= 1 && h[2] <= 20
  puts "invalid header"
  exit
end
n, d, c = h
ps = []
prev = 0
errs = []
lines[1..].each_with_index do |l, i|
  next if l.strip.empty?
  v = ints(l)
  if v && v.size == 3 && v[1] >= 1 && v[1] <= n && v[2] >= 1 && v[2] <= n && v[1] != v[2] && v[0] <= 1000 && v[0] >= prev
    prev = v[0]
    ps << v
  else
    errs << "line #{i + 2}: invalid request"
  end
end
puts errs
if ps.empty?
  puts "no passengers"
  exit
end
m = ps.size
pick = Array.new(m); drop = Array.new(m)
state = Array.new(m, :future) # :wait, :ride, :done
f = 1; t = 0; dir = :idle
out = []
dropped = 0
while dropped < m
  m.times { |i| state[i] = :wait if state[i] == :future && ps[i][0] <= t }
  any = false
  m.times do |i|
    if state[i] == :ride && ps[i][2] == f
      state[i] = :done; drop[i] = t; dropped += 1; any = true
      out << "t=#{t} floor #{f} drop P#{i + 1}"
    end
  end
  targets = []
  m.times do |i|
    targets << ps[i][2] if state[i] == :ride
    targets << ps[i][1] if state[i] == :wait
  end
  up = targets.any? { |x| x > f }
  dn = targets.any? { |x| x < f }
  if dir == :up
    dir = up ? :up : (dn ? :down : :idle)
  elsif dir == :down
    dir = dn ? :down : (up ? :up : :idle)
  end
  if dir == :idle && !targets.empty?
    near = targets.min_by { |x| [(x - f).abs, x] }
    if near == f
      i = (0...m).find { |k| state[k] == :wait && ps[k][1] == f }
      dir = ps[i][2] > f ? :up : :down
    else
      dir = near > f ? :up : :down
    end
  end
  riding = state.count(:ride)
  m.times do |i|
    next unless state[i] == :wait && ps[i][1] == f
    pd = ps[i][2] > f ? :up : :down
    next unless pd == dir
    break if riding >= c
    state[i] = :ride; pick[i] = t; riding += 1; any = true
    out << "t=#{t} floor #{f} pick P#{i + 1}"
  end
  if any
    t += d
  else
    f += 1 if dir == :up
    f -= 1 if dir == :down
    t += 1
  end
end
puts out
tw = 0; tr = 0
m.times do |i|
  w = pick[i] - ps[i][0]; r = drop[i] - pick[i]
  tw += w; tr += r
  puts "P#{i + 1} wait #{w} ride #{r}"
end
puts format("average wait %.2f ride %.2f", tw.to_f / m, tr.to_f / m)
puts "done at t=#{drop.max}"

lines = $stdin.read.to_s.b.split("\n", -1)
lines.pop if lines.last == ""
int = ->(s) { s.match?(/\A[0-9]+\z/) }
ws = /[ \t\r\f\v]+/n
hidx = lines.index { |l| !l.strip.empty? }
hdr = hidx && lines[hidx].split(ws).reject(&:empty?)
unless hdr && hdr.size == 3 && hdr.all? { |x| int.(x) }
  puts "invalid header"
  exit
end
n, dt, cap = hdr.map(&:to_i)
unless (2..50).cover?(n) && (0..5).cover?(dt) && (1..20).cover?(cap)
  puts "invalid header"
  exit
end
pass = []
prevT = 0
lastT = nil
lines.each_with_index do |l, i|
  next if i <= hidx
  next if l.strip.empty?
  tk = l.split(ws).reject(&:empty?)
  ok = tk.size == 3 && tk.all? { |x| int.(x) }
  if ok
    t, f, g = tk.map(&:to_i)
    ok = t <= 1000 && f >= 1 && f <= n && g >= 1 && g <= n && f != g && (lastT.nil? || t >= lastT)
  end
  if ok
    pass << { t: t, f: f, g: g, pick: nil, drop: nil }
    lastT = t
  else
    puts "line #{i + 1}: invalid request"
  end
end
if pass.empty?
  puts "no passengers"
  exit
end
f = 1
t = 0
dir = :idle
waiting = []
riders = []
dropped = 0
total = pass.size
pending = (0...total).to_a
last = 0
while dropped < total
  while !pending.empty? && pass[pending[0]][:t] <= t
    waiting << pending.shift
  end
  changed = false
  off = riders.select { |p| pass[p][:g] == f }.sort
  off.each do |p|
    puts "t=#{t} floor #{f} drop P#{p + 1}"
    pass[p][:drop] = t
    last = t
    dropped += 1
    changed = true
  end
  riders -= off
  targets = riders.map { |p| pass[p][:g] } + waiting.map { |p| pass[p][:f] }
  up = targets.any? { |x| x > f }
  down = targets.any? { |x| x < f }
  case dir
  when :up
    dir = up ? :up : (down ? :down : :idle)
  when :down
    dir = down ? :down : (up ? :up : :idle)
  end
  if dir == :idle && !targets.empty?
    best = targets.min_by { |x| [(x - f).abs, x] }
    if best > f
      dir = :up
    elsif best < f
      dir = :down
    else
      p0 = waiting.select { |p| pass[p][:f] == f }.min
      dir = pass[p0][:g] > f ? :up : :down
    end
  end
  if dir != :idle
    cand = waiting.select { |p| pass[p][:f] == f && ((pass[p][:g] > f ? :up : :down) == dir) }.sort
    cand.each do |p|
      break if riders.size >= cap
      puts "t=#{t} floor #{f} pick P#{p + 1}"
      pass[p][:pick] = t
      riders << p
      waiting.delete(p)
      changed = true
    end
  end
  if changed
    t += dt
  else
    f += 1 if dir == :up
    f -= 1 if dir == :down
    t += 1
  end
end
sw = 0
sr = 0
pass.each_with_index do |p, i|
  w = p[:pick] - p[:t]
  r = p[:drop] - p[:pick]
  sw += w
  sr += r
  puts "P#{i + 1} wait #{w} ride #{r}"
end
puts format("average wait %.2f ride %.2f", sw.to_f / total, sr.to_f / total)
puts "done at t=#{last}"

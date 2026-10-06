lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
num = ->(s) { s =~ /\A\d+\z/ ? s.to_i : nil }
h = (lines[0] || "").split
hv = h.size == 3 ? h.map { |x| num.(x) } : nil
n, d, c = hv
if hv.nil? || hv.any?(&:nil?) || !(2..50).cover?(n) || !(0..5).cover?(d) || !(1..20).cover?(c)
  puts "invalid header"
  exit
end
reqs = []
prev = nil
lines[1..].each_with_index do |ln, i|
  k = i + 2
  next if ln.strip.empty?
  tk = ln.split
  v = tk.size == 3 ? tk.map { |x| num.(x) } : nil
  ok = v && v.none?(&:nil?)
  if ok
    t, f, g = v
    ok = (1..n).cover?(f) && (1..n).cover?(g) && f != g && t <= 1000 && (prev.nil? || t >= prev)
  end
  if ok
    reqs << { t: t, f: f, g: g }
    prev = t
  else
    puts "line #{k}: invalid request"
  end
end
if reqs.empty?
  puts "no passengers"
  exit
end
reqs.each_with_index { |r, i| r[:id] = i + 1 }
t = 0; f = 1; dir = :idle
waiting = []; riding = []; pending = reqs.dup
done = 0
out = []
until done == reqs.size
  while pending.first && pending.first[:t] <= t
    waiting << pending.shift
  end
  offs = riding.select { |r| r[:g] == f }.sort_by { |r| r[:id] }
  offs.each { |r| r[:drop] = t; out << "t=#{t} floor #{f} drop P#{r[:id]}"; done += 1 }
  riding -= offs
  targets = riding.map { |r| r[:g] } + waiting.map { |r| r[:f] }
  case dir
  when :up
    dir = targets.any? { |x| x > f } ? :up : (targets.any? { |x| x < f } ? :down : :idle)
  when :down
    dir = targets.any? { |x| x < f } ? :down : (targets.any? { |x| x > f } ? :up : :idle)
  end
  if dir == :idle && !targets.empty?
    best = targets.min_by { |x| [(x - f).abs, x] }
    if best > f then dir = :up
    elsif best < f then dir = :down
    else
      w = waiting.select { |r| r[:f] == f }.min_by { |r| r[:id] }
      dir = w[:g] > f ? :up : :down
    end
  end
  ons = waiting.select { |r| r[:f] == f && ((r[:g] > f ? :up : :down) == dir) }.sort_by { |r| r[:id] }
  boarded = []
  ons.each do |r|
    break if riding.size + boarded.size >= c
    boarded << r
  end
  boarded.each { |r| r[:pick] = t; out << "t=#{t} floor #{f} pick P#{r[:id]}" }
  waiting -= boarded
  riding += boarded
  if !offs.empty? || !boarded.empty?
    t += d
  else
    f += 1 if dir == :up
    f -= 1 if dir == :down
    t += 1
  end
end
puts out
reqs.each { |r| puts "P#{r[:id]} wait #{r[:pick] - r[:t]} ride #{r[:drop] - r[:pick]}" }
w = reqs.sum { |r| r[:pick] - r[:t] }.to_f / reqs.size
rd = reqs.sum { |r| r[:drop] - r[:pick] }.to_f / reqs.size
puts format("average wait %.2f ride %.2f", w, rd)
puts "done at t=#{reqs.map { |r| r[:drop] }.max}"

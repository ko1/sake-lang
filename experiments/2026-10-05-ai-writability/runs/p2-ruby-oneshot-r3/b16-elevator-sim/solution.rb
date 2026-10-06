lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
lines = lines.map { |l| l.chomp("\r") }
hdr = (lines[0] || "").split
unless hdr.size == 3 && hdr.all? { |x| x =~ /\A\d+\z/ }
  puts "invalid header"
  exit
end
n, d, c = hdr.map(&:to_i)
unless n.between?(2, 50) && d.between?(0, 5) && c.between?(1, 20)
  puts "invalid header"
  exit
end
reqs = []
prevt = nil
(1...lines.size).each do |i|
  l = lines[i]
  next if l.strip.empty?
  tk = l.split
  ok = tk.size == 3 && tk.all? { |x| x =~ /\A\d+\z/ }
  if ok
    t, f, g = tk.map(&:to_i)
    ok = f.between?(1, n) && g.between?(1, n) && f != g && t <= 1000 && (prevt.nil? || t >= prevt)
  end
  if ok
    reqs << [t, f, g]
    prevt = t
  else
    puts "line #{i + 1}: invalid request"
  end
end
if reqs.empty?
  puts "no passengers"
  exit
end
np = reqs.size
pick = Array.new(np)
drop = Array.new(np)
waiting = []
riders = []
nextp = 0
f = 1
t = 0
dir = :idle
dropped = 0
while dropped < np
  while nextp < np && reqs[nextp][0] <= t
    waiting << nextp
    nextp += 1
  end
  gone = riders.select { |p| reqs[p][2] == f }.sort
  gone.each do |p|
    puts "t=#{t} floor #{f} drop P#{p + 1}"
    drop[p] = t
    dropped += 1
  end
  riders -= gone
  targets = riders.map { |p| reqs[p][2] } + waiting.map { |p| reqs[p][1] }
  above = targets.any? { |x| x > f }
  below = targets.any? { |x| x < f }
  case dir
  when :up
    dir = above ? :up : (below ? :down : :idle)
  when :down
    dir = below ? :down : (above ? :up : :idle)
  end
  if dir == :idle && !targets.empty?
    best = targets.min_by { |x| [(x - f).abs, x] }
    if best > f
      dir = :up
    elsif best < f
      dir = :down
    else
      p0 = waiting.find { |p| reqs[p][1] == f }
      dir = reqs[p0][2] > f ? :up : :down
    end
  end
  boarded = []
  waiting.each do |p|
    break if riders.size + boarded.size >= c
    next unless reqs[p][1] == f
    pd = reqs[p][2] > f ? :up : :down
    boarded << p if pd == dir
  end
  boarded.each do |p|
    puts "t=#{t} floor #{f} pick P#{p + 1}"
    pick[p] = t
  end
  waiting -= boarded
  riders += boarded
  if !gone.empty? || !boarded.empty?
    t += d
  else
    f += 1 if dir == :up
    f -= 1 if dir == :down
    t += 1
  end
end
sw = 0
sr = 0
np.times do |p|
  w = pick[p] - reqs[p][0]
  r = drop[p] - pick[p]
  sw += w
  sr += r
  puts "P#{p + 1} wait #{w} ride #{r}"
end
puts format("average wait %.2f ride %.2f", sw.to_f / np, sr.to_f / np)
puts "done at t=#{drop.max}"

lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
dig = ->(s) { s =~ /\A\d+\z/ }
h = (lines[0] || "").split
unless h.size == 3 && h.all?(&dig)
  puts "invalid header"
  exit
end
n, d, c = h.map(&:to_i)
unless n.between?(2, 50) && d.between?(0, 5) && c.between?(1, 20)
  puts "invalid header"
  exit
end
reqs = []
prev = 0
lines[1..].each_with_index do |ln, i|
  next if ln.strip.empty?
  tk = ln.split
  ok = tk.size == 3 && tk.all?(&dig)
  if ok
    t, f, g = tk.map(&:to_i)
    ok = f.between?(1, n) && g.between?(1, n) && f != g && t <= 1000 && t >= prev
  end
  if ok
    reqs << [t, f, g]
    prev = t
  else
    puts "line #{i + 2}: invalid request"
  end
end
if reqs.empty?
  puts "no passengers"
  exit
end
m = reqs.size
pick = Array.new(m)
drop = Array.new(m)
state = Array.new(m, :future) # :future :waiting :riding :done
t = 0
f = 1
dir = 0
done = 0
while done < m
  m.times { |i| state[i] = :waiting if state[i] == :future && reqs[i][0] <= t }
  out = []
  m.times do |i|
    if state[i] == :riding && reqs[i][2] == f
      state[i] = :done
      drop[i] = t
      done += 1
      out << "t=#{t} floor #{f} drop P#{i + 1}"
    end
  end
  break if done == m && out.empty? && false
  targets = []
  m.times do |i|
    targets << reqs[i][2] if state[i] == :riding
    targets << reqs[i][1] if state[i] == :waiting
  end
  if dir == 1
    dir = targets.any? { |x| x > f } ? 1 : (targets.any? { |x| x < f } ? -1 : 0)
  elsif dir == -1
    dir = targets.any? { |x| x < f } ? -1 : (targets.any? { |x| x > f } ? 1 : 0)
  end
  if dir == 0 && !targets.empty?
    best = targets.min_by { |x| [(x - f).abs, x] }
    if best == f
      i = (0...m).find { |k| state[k] == :waiting && reqs[k][1] == f }
      dir = reqs[i][2] > f ? 1 : -1
    else
      dir = best > f ? 1 : -1
    end
  end
  riders = state.count(:riding)
  if dir != 0
    m.times do |i|
      break if riders >= c
      next unless state[i] == :waiting && reqs[i][1] == f
      next unless (reqs[i][2] > f ? 1 : -1) == dir
      state[i] = :riding
      pick[i] = t
      riders += 1
      out << "t=#{t} floor #{f} pick P#{i + 1}"
    end
  end
  puts out
  if !out.empty?
    t += d
  else
    f += dir
    t += 1
  end
end
sw = 0
sr = 0
m.times do |i|
  w = pick[i] - reqs[i][0]
  r = drop[i] - pick[i]
  sw += w
  sr += r
  puts "P#{i + 1} wait #{w} ride #{r}"
end
puts format("average wait %.2f ride %.2f", sw.to_f / m, sr.to_f / m)
puts "done at t=#{drop.max}"

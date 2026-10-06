lines = $stdin.each_line.map(&:chomp)
h = (lines[0] || "").split
unless h.size == 3 && h.all? { |x| x =~ /\A\d+\z/ } &&
       (2..50).cover?(h[0].to_i) && (0..5).cover?(h[1].to_i) && (1..20).cover?(h[2].to_i)
  puts "invalid header"
  exit
end
nf, dt, cap = h.map(&:to_i)
reqs = []
out = []
lines.each_with_index do |l, i|
  next if i == 0
  f = l.split
  next if f.empty?
  ok = f.size == 3 && f.all? { |x| x =~ /\A\d+\z/ }
  if ok
    t, a, b = f.map(&:to_i)
    ok = (1..nf).cover?(a) && (1..nf).cover?(b) && a != b && t <= 1000 &&
         (reqs.empty? || t >= reqs[-1][0])
  end
  if ok
    reqs << [t, a, b]
  else
    out << "line #{i + 1}: invalid request"
  end
end
if reqs.empty?
  puts out, "no passengers"
  exit
end
n = reqs.size
pick = Array.new(n)
drop = Array.new(n)
state = Array.new(n, :future) # :future :waiting :riding :done
t = 0
f = 1
dir = :idle
last = 0
while state.any? { |s| s != :done }
  n.times { |i| state[i] = :waiting if state[i] == :future && reqs[i][0] <= t }
  changed = false
  n.times do |i|
    if state[i] == :riding && reqs[i][2] == f
      state[i] = :done
      drop[i] = t
      last = t
      out << "t=#{t} floor #{f} drop P#{i + 1}"
      changed = true
    end
  end
  targets = []
  n.times do |i|
    targets << reqs[i][2] if state[i] == :riding
    targets << reqs[i][1] if state[i] == :waiting
  end
  above = targets.any? { |x| x > f }
  below = targets.any? { |x| x < f }
  case dir
  when :up then dir = above ? :up : below ? :down : :idle
  when :down then dir = below ? :down : above ? :up : :idle
  end
  if dir == :idle && !targets.empty?
    best = targets.min_by { |x| [(x - f).abs, x] }
    if best > f then dir = :up
    elsif best < f then dir = :down
    else
      i = (0...n).find { |k| state[k] == :waiting && reqs[k][1] == f }
      dir = reqs[i][2] > f ? :up : :down
    end
  end
  if dir != :idle
    riders = state.count(:riding)
    n.times do |i|
      next unless state[i] == :waiting && reqs[i][1] == f
      pd = reqs[i][2] > f ? :up : :down
      next unless pd == dir && riders < cap
      state[i] = :riding
      pick[i] = t
      riders += 1
      out << "t=#{t} floor #{f} pick P#{i + 1}"
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
n.times do |i|
  w = pick[i] - reqs[i][0]
  r = drop[i] - pick[i]
  sw += w
  sr += r
  out << "P#{i + 1} wait #{w} ride #{r}"
end
out << format("average wait %.2f ride %.2f", sw.to_f / n, sr.to_f / n)
out << "done at t=#{last}"
puts out

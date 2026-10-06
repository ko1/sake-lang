lines = $stdin.each_line.map(&:chomp)
h = (lines[0] || "").split(/\s+/).reject(&:empty?)
unless h.size == 3 && h.all? { |x| x =~ /\A\d+\z/ } && (2..50).cover?(h[0].to_i) &&
       (0..5).cover?(h[1].to_i) && (1..20).cover?(h[2].to_i)
  puts "invalid header"
  exit
end
n, d, cap = h.map(&:to_i)

pass = [] # [T, F, G]
last_t = nil
lines.each_with_index do |raw, i|
  next if i == 0
  f = raw.split(/\s+/).reject(&:empty?)
  next if f.empty?
  ok = f.size == 3 && f.all? { |x| x =~ /\A\d+\z/ }
  if ok
    t, fl, g = f.map(&:to_i)
    ok = (1..n).cover?(fl) && (1..n).cover?(g) && fl != g && t <= 1000 && (last_t.nil? || t >= last_t)
  end
  if ok
    pass << [t, fl, g]
    last_t = t
  else
    puts "line #{i + 1}: invalid request"
  end
end

if pass.empty?
  puts "no passengers"
  exit
end

np = pass.size
state = Array.new(np, :future) # :future, :waiting, :riding, :done
pick = Array.new(np)
drop = Array.new(np)
f = 1
t = 0
dir = :idle
dirof = ->(i) { pass[i][2] > pass[i][1] ? :up : :down }

while state.any? { |s| s != :done }
  np.times { |i| state[i] = :waiting if state[i] == :future && pass[i][0] <= t }
  moved = false
  # drop-offs
  riders = (0...np).select { |i| state[i] == :riding }
  (riders.select { |i| pass[i][2] == f }).each do |i|
    state[i] = :done
    drop[i] = t
    puts "t=#{t} floor #{f} drop P#{i + 1}"
    moved = true
  end
  waiting = (0...np).select { |i| state[i] == :waiting }
  riders = (0...np).select { |i| state[i] == :riding }
  targets = riders.map { |i| pass[i][2] } + waiting.map { |i| pass[i][1] }
  case dir
  when :up
    dir = targets.any? { |x| x > f } ? :up : targets.any? { |x| x < f } ? :down : :idle
  when :down
    dir = targets.any? { |x| x < f } ? :down : targets.any? { |x| x > f } ? :up : :idle
  end
  if dir == :idle && !targets.empty?
    near = targets.min_by { |x| [(x - f).abs, x] }
    if near == f
      lo = waiting.select { |i| pass[i][1] == f }.min
      dir = dirof.call(lo)
    else
      dir = near > f ? :up : :down
    end
  end
  boarders = waiting.select { |i| pass[i][1] == f && dir != :idle && dirof.call(i) == dir }.sort
  boarders.each do |i|
    break unless riders.size + (0) < cap
    state[i] = :riding
    pick[i] = t
    riders << i
    puts "t=#{t} floor #{f} pick P#{i + 1}"
    moved = true
  end
  if moved
    t += d
  else
    f += 1 if dir == :up
    f -= 1 if dir == :down
    t += 1
  end
end

sw = 0
sr = 0
np.times do |i|
  w = pick[i] - pass[i][0]
  r = drop[i] - pick[i]
  sw += w
  sr += r
  puts "P#{i + 1} wait #{w} ride #{r}"
end
puts format("average wait %.2f ride %.2f", sw.to_f / np, sr.to_f / np)
puts "done at t=#{drop.max}"

lines = STDIN.read.split("\n", -1)
lines.pop if lines.last == ""
_, first, step, cap, grace = lines[0].split
first, step, cap, grace = [first, step, cap, grace].map(&:to_i)

def money(c)
  format("%d.%02d", c / 100, c % 100)
end

fee = lambda do |m|
  next 0 if m <= grace
  d, r = m.divmod(1440)
  part = r == 0 ? 0 : first + step * ([r - 60, 0].max + 29) / 30
  d * cap + [cap, part].min
end

inside = {}
stats = Hash.new { |h, k| h[k] = [0, 0] }
day = 0
prev = nil
(1...lines.size).each do |i|
  l = lines[i]
  n = i + 1
  next if l.strip.empty? && !l.include?("\t") && l.delete(" ").empty?
  tk = l.split(" ")
  if tk.size != 3 || l =~ /[^ -~]/ || l.start_with?(" ") && false
    puts "line #{n}: invalid"
    next
  end
  tm, op, plate = tk
  unless tm =~ /\A([01]\d|2[0-3]):([0-5]\d)\z/ && (op == "IN" || op == "OUT") && plate =~ /\A[A-Z0-9]{1,8}\z/
    puts "line #{n}: invalid"
    next
  end
  cur = $1.to_i * 60 + $2.to_i
  day += 1 if prev && cur < prev
  prev = cur
  abs = day * 1440 + cur
  if op == "IN"
    if inside.key?(plate)
      puts "line #{n}: #{plate} already inside"
    else
      inside[plate] = abs
    end
  else
    if inside.key?(plate)
      stay = abs - inside.delete(plate)
      f = fee.(stay)
      puts format("%s %d:%02d %s", plate, stay / 60, stay % 60, money(f))
      stats[plate][0] += 1
      stats[plate][1] += f
    else
      puts "line #{n}: #{plate} not inside"
    end
  end
end
puts "--- summary"
stats.sort_by { |p, (_, r)| [-r, p.b] }.each { |p, (e, r)| puts "#{p} #{e} #{money(r)}" }
puts "total #{stats.values.sum { |v| v[0] }} #{money(stats.values.sum { |v| v[1] })}"
puts "inside: " + (inside.empty? ? "none" : inside.keys.sort_by(&:b).join(", "))

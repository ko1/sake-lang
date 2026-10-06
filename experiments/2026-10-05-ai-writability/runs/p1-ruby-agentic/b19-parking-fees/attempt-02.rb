lines = $stdin.binmode.read.each_line.map(&:chomp)
_, first, step, cap, grace = lines[0].split.map { |x| x.to_i }
inside = {}
stats = Hash.new { |h, k| h[k] = [0, 0] }
day = 0
prev = nil
ev = /\A([01]\d|2[0-3]):([0-5]\d) +(IN|OUT) +([A-Z0-9]{1,8})\z/n
money = ->(c) { format("%d.%02d", c / 100, c % 100) }
lines[1..].to_a.each_with_index do |ln, i|
  no = i + 2
  next if ln =~ /\A *\z/
  m = ev.match(ln)
  unless m
    puts "line #{no}: invalid"; next
  end
  tm = m[1].to_i * 60 + m[2].to_i
  day += 1 if prev && tm < prev
  prev = tm
  abs = day * 1440 + tm
  plate = m[4]
  if m[3] == "IN"
    if inside.key?(plate)
      puts "line #{no}: #{plate} already inside"
    else
      inside[plate] = abs
    end
  else
    unless inside.key?(plate)
      puts "line #{no}: #{plate} not inside"; next
    end
    mins = abs - inside.delete(plate)
    fee = 0
    if mins > grace
      d, r = mins.divmod(1440)
      part = r.zero? ? 0 : first + step * (([r - 60, 0].max + 29) / 30)
      fee = d * cap + [cap, part].min
    end
    puts format("%s %d:%02d %s", plate, mins / 60, mins % 60, money.(fee))
    stats[plate][0] += 1
    stats[plate][1] += fee
  end
end
puts "--- summary"
stats.sort_by { |p, (_, r)| [-r, p] }.each { |p, (n, r)| puts "#{p} #{n} #{money.(r)}" }
puts "total #{stats.values.sum { |v| v[0] }} #{money.(stats.values.sum { |v| v[1] })}"
puts "inside: " + (inside.empty? ? "none" : inside.keys.sort.join(", "))

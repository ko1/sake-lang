lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
_, first, step, cap, grace = lines[0].split
first = first.to_i; step = step.to_i; cap = cap.to_i; grace = grace.to_i
money = ->(c) { format("%d.%02d", c / 100, c % 100) }
inside = {}
rev = Hash.new(0)
exits = Hash.new(0)
day = 0
prev = nil
lines[1..].each_with_index do |raw, i|
  ln = raw.chomp
  n = i + 2
  next if ln.strip.empty? && ln !~ /[^ ]/
  m = ln.match(/\A(\d\d):(\d\d) +(IN|OUT) +([A-Z0-9]{1,8})\z/)
  if m.nil? || m[1].to_i > 23 || m[2].to_i > 59
    puts "line #{n}: invalid"
    next
  end
  tm = m[1].to_i * 60 + m[2].to_i
  day += 1 if prev && tm < prev
  prev = tm
  abs = day * 1440 + tm
  plate = m[4]
  if m[3] == "IN"
    if inside.key?(plate)
      puts "line #{n}: #{plate} already inside"
    else
      inside[plate] = abs
    end
  else
    unless inside.key?(plate)
      puts "line #{n}: #{plate} not inside"
      next
    end
    stay = abs - inside.delete(plate)
    fee = 0
    if stay > grace
      d, r = stay.divmod(1440)
      part = 0
      if r > 0
        extra = r > 60 ? (r - 60 + 29) / 30 : 0
        part = first + step * extra
      end
      fee = d * cap + [cap, part].min
    end
    rev[plate] += fee
    exits[plate] += 1
    puts format("%s %d:%02d %s", plate, stay / 60, stay % 60, money.(fee))
  end
end
puts "--- summary"
rev.keys.sort_by { |p| [-rev[p], p] }.each { |p| puts "#{p} #{exits[p]} #{money.(rev[p])}" }
puts "total #{exits.values.sum} #{money.(rev.values.sum)}"
puts "inside: " + (inside.empty? ? "none" : inside.keys.sort.join(", "))

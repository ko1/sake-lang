lines = $stdin.read.each_line.map { |l| l.chomp.chomp("\r") }
_, first, step, cap, grace = lines[0].split.map { |x| x =~ /\A\d+\z/ ? x.to_i : 0 }

def money(c)
  format("%d.%02d", c / 100, c % 100)
end

inside = {}
stats = Hash.new { |h, k| h[k] = [0, 0] }
day = 0
prev = nil
tot_n = 0
tot_r = 0
(1...lines.size).each do |i|
  l = lines[i]
  n = i + 1
  next if l =~ /\A *\z/
  m = /\A *([0-9]{2}):([0-9]{2}) +(IN|OUT) +([A-Z0-9]{1,8}) *\z/.match(l)
  hh = m && m[1].to_i
  mm = m && m[2].to_i
  unless m && hh <= 23 && mm <= 59
    puts "line #{n}: invalid"
    next
  end
  tm = hh * 60 + mm
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
    mins = abs - inside.delete(plate)
    fee = 0
    if mins > grace
      d = mins / 1440
      r = mins % 1440
      part = 0
      if r > 0
        extra = r > 60 ? (r - 60 + 29) / 30 : 0
        part = first + step * extra
      end
      fee = d * cap + [cap, part].min
    end
    puts format("%s %d:%02d %s", plate, mins / 60, mins % 60, money(fee))
    stats[plate][0] += 1
    stats[plate][1] += fee
    tot_n += 1
    tot_r += fee
  end
end
puts "--- summary"
stats.sort_by { |p, (_, r)| [-r, p] }.each do |p, (c, r)|
  puts "#{p} #{c} #{money(r)}"
end
puts "total #{tot_n} #{money(tot_r)}"
puts "inside: " + (inside.empty? ? "none" : inside.keys.sort.join(", "))

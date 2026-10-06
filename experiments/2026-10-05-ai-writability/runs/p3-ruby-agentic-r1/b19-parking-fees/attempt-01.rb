lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
_, first, step, cap, grace = lines[0].split.then { |a| [a[0]] + a[1..].map(&:to_i) }
inside = {}
rev = Hash.new(0)
cnt = Hash.new(0)
day = 0
prev = nil
def money(c) = format("%d.%02d", c / 100, c % 100)
lines[1..].each_with_index do |l, i|
  no = i + 2
  l = l.chomp("\r")
  next if l =~ /\A *\z/
  m = l.match(/\A(\d\d):(\d\d) +(IN|OUT) +([A-Z0-9]{1,8})\z/)
  if !m || m[1].to_i > 23 || m[2].to_i > 59
    puts "line #{no}: invalid"; next
  end
  mins = m[1].to_i * 60 + m[2].to_i
  day += 1 if prev && mins < prev
  prev = mins
  abs = day * 1440 + mins
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
    stay = abs - inside.delete(plate)
    fee = 0
    if stay > grace
      d, r = stay.divmod(1440)
      part = r == 0 ? 0 : (r <= 60 ? first : first + step * ((r - 60 + 29) / 30))
      fee = d * cap + [cap, part].min
    end
    rev[plate] += fee
    cnt[plate] += 1
    puts format("%s %d:%02d %s", plate, stay / 60, stay % 60, money(fee))
  end
end
puts "--- summary"
rev.keys.sort_by { |p| [-rev[p], p.b] }.each { |p| puts "#{p} #{cnt[p]} #{money(rev[p])}" }
puts "total #{cnt.values.sum} #{money(rev.values.sum)}"
puts "inside: " + (inside.empty? ? "none" : inside.keys.sort_by(&:b).join(", "))

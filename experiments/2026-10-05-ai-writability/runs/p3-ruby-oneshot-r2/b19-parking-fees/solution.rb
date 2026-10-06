lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
lines = lines.map { |l| l.chomp("\r") }
first, step, cap, grace = lines[0].split[1, 4].map(&:to_i)
money = ->(c) { format("%d.%02d", c / 100, c % 100) }
part = lambda do |r|
  next 0 if r == 0
  k = r <= 60 ? 0 : (r - 60 + 29) / 30
  first + step * k
end
inside = {}
stats = Hash.new { |h, k| h[k] = [0, 0] }
day = 0
prev = nil
out = []
lines.each_with_index do |l, i|
  next if i == 0
  no = i + 1
  next if l =~ /\A *\z/
  m = /\A *(\d\d):(\d\d) +(IN|OUT) +([A-Z0-9]{1,8}) *\z/.match(l)
  hh = m && m[1].to_i
  mm = m && m[2].to_i
  if m.nil? || hh > 23 || mm > 59
    out << "line #{no}: invalid"
    next
  end
  tm = hh * 60 + mm
  day += 1 if prev && tm < prev
  prev = tm
  abs = day * 1440 + tm
  plate = m[4]
  if m[3] == "IN"
    if inside.key?(plate)
      out << "line #{no}: #{plate} already inside"
    else
      inside[plate] = abs
    end
  else
    unless inside.key?(plate)
      out << "line #{no}: #{plate} not inside"
      next
    end
    stay = abs - inside.delete(plate)
    fee = 0
    if stay > grace
      d = stay / 1440
      r = stay % 1440
      fee = d * cap + [cap, part.(r)].min
    end
    out << format("%s %d:%02d %s", plate, stay / 60, stay % 60, money.(fee))
    stats[plate][0] += 1
    stats[plate][1] += fee
  end
end
puts out
puts "--- summary"
stats.sort_by { |p, (_, rev)| [-rev, p] }.each { |p, (n, rev)| puts "#{p} #{n} #{money.(rev)}" }
puts "total #{stats.values.sum { |v| v[0] }} #{money.(stats.values.sum { |v| v[1] })}"
puts "inside: " + (inside.empty? ? "none" : inside.keys.sort.join(", "))

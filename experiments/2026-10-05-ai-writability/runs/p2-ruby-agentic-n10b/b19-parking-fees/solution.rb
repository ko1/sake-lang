lines = $stdin.each_line.map(&:chomp)
_, first, step, cap, grace = lines[0].split.then { |a| [a[0]] + a[1..].map(&:to_i) }
inside = {}
exits = Hash.new(0)
rev = Hash.new(0)
day = 0
prev = nil
out = []
money = ->(c) { format("%d.%02d", c / 100, c % 100) }
lines.each_with_index do |l, i|
  next if i == 0
  n = i + 1
  next if l.strip.empty?
  m = /\A(\d\d):(\d\d) +(IN|OUT) +([A-Z0-9]{1,8})\z/.match(l.strip)
  unless m && m[1].to_i <= 23 && m[2].to_i <= 59
    out << "line #{n}: invalid"
    next
  end
  tm = m[1].to_i * 60 + m[2].to_i
  day += 1 if prev && tm < prev
  prev = tm
  abs = day * 1440 + tm
  plate = m[4]
  if m[3] == "IN"
    if inside.key?(plate)
      out << "line #{n}: #{plate} already inside"
    else
      inside[plate] = abs
    end
  else
    unless inside.key?(plate)
      out << "line #{n}: #{plate} not inside"
      next
    end
    stay = abs - inside.delete(plate)
    fee = 0
    if stay > grace
      d, r = stay.divmod(1440)
      part = r == 0 ? 0 : first + step * (r > 60 ? (r - 60 + 29) / 30 : 0)
      fee = d * cap + [cap, part].min
    end
    exits[plate] += 1
    rev[plate] += fee
    out << "#{plate} #{stay / 60}:#{format("%02d", stay % 60)} #{money.(fee)}"
  end
end
out << "--- summary"
exits.keys.sort_by { |p| [-rev[p], p] }.each { |p| out << "#{p} #{exits[p]} #{money.(rev[p])}" }
out << "total #{exits.values.sum} #{money.(rev.values.sum)}"
out << "inside: #{inside.empty? ? "none" : inside.keys.sort.join(", ")}"
puts out

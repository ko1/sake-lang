lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
_, first, step, cap, grace = lines[0].split.map { |x| x =~ /\A\d+\z/ ? x.to_i : x }

def money(c)
  format("%d.%02d", c / 100, c % 100)
end

part = lambda do |r|
  next 0 if r == 0
  extra = r > 60 ? (r - 60 + 29) / 30 : 0
  first + step * extra
end

day = 0
prev = nil
inside = {}
stats = Hash.new { |h, k| h[k] = [0, 0] }
lines[1..].each_with_index do |ln, i|
  no = i + 2
  next if ln.strip.empty? && ln !~ /[^ ]/
  m = ln.match(/\A(\d\d):(\d\d) +(IN|OUT) +([A-Z0-9]{1,8})\z/)
  hh = m && m[1].to_i
  mm = m && m[2].to_i
  unless m && hh <= 23 && mm <= 59
    puts "line #{no}: invalid"
    next
  end
  tod = hh * 60 + mm
  day += 1 if prev && tod < prev
  prev = tod
  abs = day * 1440 + tod
  plate = m[4]
  if m[3] == "IN"
    if inside.key?(plate)
      puts "line #{no}: #{plate} already inside"
    else
      inside[plate] = abs
    end
  else
    if !inside.key?(plate)
      puts "line #{no}: #{plate} not inside"
    else
      stay = abs - inside.delete(plate)
      fee = if stay <= grace
              0
            else
              d, r = stay.divmod(1440)
              d * cap + [cap, part.(r)].min
            end
      puts "#{plate} #{stay / 60}:#{format('%02d', stay % 60)} #{money(fee)}"
      stats[plate][0] += 1
      stats[plate][1] += fee
    end
  end
end
puts "--- summary"
stats.sort_by { |p, (_, rev)| [-rev, p.b] }.each do |p, (n, rev)|
  puts "#{p} #{n} #{money(rev)}"
end
puts "total #{stats.values.sum { |v| v[0] }} #{money(stats.values.sum { |v| v[1] })}"
pl = inside.keys.sort_by(&:b)
puts "inside: #{pl.empty? ? 'none' : pl.join(', ')}"

def money(c) = format("%d.%02d", c / 100, c % 100)

lines = $stdin.each_line.map(&:chomp)
h = lines[0].split(/ +/).reject(&:empty?)
first, step, cap, grace = h[1..4].map(&:to_i)

def fee(stay, first, step, cap, grace)
  return 0 if stay <= grace
  d, r = stay.divmod(1440)
  part = r == 0 ? 0 : first + step * [(r - 60 + 29) / 30, 0].max
  d * cap + [cap, part].min
end

inside = {}
stats = Hash.new { |hh, k| hh[k] = [0, 0] }
day = 0
prev = nil

lines.each_with_index do |raw, i|
  next if i == 0
  no = i + 1
  next if raw.strip.empty?
  f = raw.split(/ +/).reject(&:empty?)
  unless f.size == 3 && f[0] =~ /\A([01]\d|2[0-3]):([0-5]\d)\z/ && %w[IN OUT].include?(f[1]) &&
         f[2] =~ /\A[A-Z0-9]{1,8}\z/
    puts "line #{no}: invalid"
    next
  end
  hh, mm = f[0].split(":").map(&:to_i)
  tod = hh * 60 + mm
  day += 1 if prev && tod < prev
  prev = tod
  abs = day * 1440 + tod
  plate = f[2]
  if f[1] == "IN"
    if inside.key?(plate)
      puts "line #{no}: #{plate} already inside"
    else
      inside[plate] = abs
    end
  else
    unless inside.key?(plate)
      puts "line #{no}: #{plate} not inside"
      next
    end
    stay = abs - inside.delete(plate)
    fe = fee(stay, first, step, cap, grace)
    stats[plate][0] += 1
    stats[plate][1] += fe
    puts "#{plate} #{stay / 60}:#{format('%02d', stay % 60)} #{money(fe)}"
  end
end

puts "--- summary"
stats.sort_by { |p, s| [-s[1], p.b] }.each { |p, s| puts "#{p} #{s[0]} #{money(s[1])}" }
puts "total #{stats.values.sum { |s| s[0] }} #{money(stats.values.sum { |s| s[1] })}"
puts "inside: " + (inside.empty? ? "none" : inside.keys.sort_by(&:b).join(", "))

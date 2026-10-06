lines = $stdin.read.split("\n")
_, first, step, cap, grace = lines[0].split
first = first.to_i; step = step.to_i; cap = cap.to_i; grace = grace.to_i
def money(c) = format("%d.%02d", c / 100, c % 100)
part = lambda do |r|
  next 0 if r == 0
  r <= 60 ? first : first + step * ((r - 60 + 29) / 30)
end
inside = {}
stats = Hash.new { |h, k| h[k] = [0, 0] }
day = 0; prev = nil
lines[1..].each_with_index do |raw, i|
  n = i + 2
  ln = raw.chomp("\r")
  next if ln.strip.empty? && ln =~ /\A *\z/
  m = ln.match(/\A *([0-2]\d):([0-5]\d) +(IN|OUT) +([A-Z0-9]{1,8}) *\z/)
  if m.nil? || m[1].to_i > 23
    puts "line #{n}: invalid"; next
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
      puts "line #{n}: #{plate} not inside"; next
    end
    stay = abs - inside.delete(plate)
    fee = if stay <= grace then 0
          else
            d, r = stay.divmod(1440)
            d * cap + [cap, part.(r)].min
          end
    puts format("%s %d:%02d %s", plate, stay / 60, stay % 60, money(fee))
    stats[plate][0] += 1; stats[plate][1] += fee
  end
end
puts "--- summary"
stats.sort_by { |p, (_, rev)| [-rev, p.b] }.each { |p, (e, rev)| puts "#{p} #{e} #{money(rev)}" }
puts "total #{stats.values.sum { |e, _| e }} #{money(stats.values.sum { |_, r| r })}"
puts "inside: #{inside.empty? ? 'none' : inside.keys.sort_by(&:b).join(', ')}"

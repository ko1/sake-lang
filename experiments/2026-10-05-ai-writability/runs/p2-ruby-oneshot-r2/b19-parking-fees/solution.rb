lines = $stdin.readlines.map(&:chomp)
_, first, step, cap, grace = (lines[0] || "RATE 0 0 0 0").split
first = first.to_i; step = step.to_i; cap = cap.to_i; grace = grace.to_i

def money(c)
  format("%d.%02d", c / 100, c % 100)
end

def part(r, first, step)
  return 0 if r == 0
  extra = r > 60 ? (r - 60 + 29) / 30 : 0
  first + step * extra
end

inside = {}
stats = Hash.new { |hh, k| hh[k] = [0, 0] }
day = 0
prev = nil
(lines[1..] || []).each_with_index do |ln, i|
  num = i + 2
  next if ln.match?(/\A *\z/)
  tk = ln.sub(/\A +/, "").sub(/ +\z/, "").split(/ +/)
  m = tk.size == 3 ? tk[0].match(/\A([01]\d|2[0-3]):([0-5]\d)\z/) : nil
  if m.nil? || !%w[IN OUT].include?(tk[1]) || !tk[2].match?(/\A[A-Z0-9]{1,8}\z/)
    puts "line #{num}: invalid"
    next
  end
  clock = m[1].to_i * 60 + m[2].to_i
  day += 1 if prev && clock < prev
  prev = clock
  abs = day * 1440 + clock
  plate = tk[2]
  if tk[1] == "IN"
    if inside.key?(plate)
      puts "line #{num}: #{plate} already inside"
    else
      inside[plate] = abs
    end
  else
    unless inside.key?(plate)
      puts "line #{num}: #{plate} not inside"
      next
    end
    mins = abs - inside.delete(plate)
    fee = if mins <= grace
            0
          else
            d, r = mins.divmod(1440)
            d * cap + [cap, part(r, first, step)].min
          end
    puts "#{plate} #{mins / 60}:#{format('%02d', mins % 60)} #{money(fee)}"
    stats[plate][0] += 1
    stats[plate][1] += fee
  end
end

puts "--- summary"
stats.sort_by { |p, (_, rev)| [-rev, p] }.each do |p, (n, rev)|
  puts "#{p} #{n} #{money(rev)}"
end
puts "total #{stats.values.sum { |v| v[0] }} #{money(stats.values.sum { |v| v[1] })}"
puts "inside: #{inside.empty? ? 'none' : inside.keys.sort.join(', ')}"

lines = $stdin.read.to_s.b.split("\n", -1)
lines.pop if lines.last == ""
h = (lines[0] || "RATE 0 0 0 0").split(" ")
first, step, cap, grace = h[1..4].map(&:to_i)
inside = {}
stats = Hash.new { |hh, k| hh[k] = [0, 0] }
day = 0
prev = nil
money = ->(c) { format("%d.%02d", c / 100, c % 100) }
fee = lambda do |stay|
  next 0 if stay <= grace
  d = stay / 1440
  r = stay % 1440
  part = r == 0 ? 0 : first + step * (((r > 60 ? r - 60 : 0) + 29) / 30)
  d * cap + [cap, part].min
end
lines.each_with_index do |raw, i|
  next if i == 0
  n = i + 1
  line = raw.chomp("\r")
  next if line.match?(/\A *\z/n)
  tk = line.sub(/\A +/, "").sub(/ +\z/, "").split(/ +/)
  m = tk.size == 3 ? /\A([0-9]{2}):([0-9]{2})\z/n.match(tk[0]) : nil
  unless m && (tk[1] == "IN" || tk[1] == "OUT") && tk[2].match?(/\A[A-Z0-9]{1,8}\z/n) &&
         m[1].to_i <= 23 && m[2].to_i <= 59
    puts "line #{n}: invalid"
    next
  end
  tm = m[1].to_i * 60 + m[2].to_i
  day += 1 if prev && tm < prev
  prev = tm
  abs = day * 1440 + tm
  plate = tk[2]
  if tk[1] == "IN"
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
    f = fee.(stay)
    puts "#{plate} #{stay / 60}:#{format('%02d', stay % 60)} #{money.(f)}"
    stats[plate][0] += 1
    stats[plate][1] += f
  end
end
puts "--- summary"
te = 0
tr = 0
stats.sort_by { |p, (_, r)| [-r, p] }.each do |p, (e, r)|
  puts "#{p} #{e} #{money.(r)}"
  te += e
  tr += r
end
puts "total #{te} #{money.(tr)}"
puts "inside: #{inside.empty? ? 'none' : inside.keys.sort.join(', ')}"

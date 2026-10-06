lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
hdr = lines[0]
f = hdr ? hdr.split : []
ok = f.size >= 2 && f.size <= 5 && f[0] =~ /\A\d+\z/ && (2..1001).cover?(f[0].to_i) &&
     f[1..].all? { |x| x =~ /\A[a-z]{1,10}\z/ } && f[1..].uniq.size == f.size - 1
unless ok
  puts "invalid header"
  exit
end
start = f[0].to_i
names = f[1..]
left = names.to_h { |n| [n, start] }
turns = names.to_h { |n| [n, 0] }
darts = names.to_h { |n| [n, 0] }
winner = nil
out = []

def val(d)
  case d
  when /\A([SDT])([1-9]|1\d|20)\z/
    [$1 == "S" ? 1 : $1 == "D" ? 2 : 3].first * $2.to_i
  when "25" then 25
  when "BULL" then 50
  when "MISS" then 0
  end
end

(1...lines.size).each do |i|
  ln = lines[i]
  n = i + 1
  w = ln.split
  next if w.empty?
  name = w[0]
  ds = w[1..]
  if winner
    out << "line #{n}: game over"
    next
  end
  unless left.key?(name)
    out << "line #{n}: unknown player #{name}"
    next
  end
  unless (1..3).cover?(ds.size)
    out << "line #{n}: expected 1 to 3 darts"
    next
  end
  bad = ds.find { |d| val(d).nil? }
  if bad
    out << "line #{n}: bad dart #{bad}"
    next
  end
  cur = left[name]
  total = 0
  result = nil
  ds.each do |d|
    darts[name] += 1
    v = val(d)
    total += v
    cur -= v
    dbl = d.start_with?("D") || d == "BULL"
    if cur < 0 || cur == 1 || (cur == 0 && !dbl)
      result = [:bust]
      break
    elsif cur == 0
      result = [:out, d]
      break
    end
  end
  turns[name] += 1
  case result&.first
  when :bust
    out << "#{name} busts, #{left[name]} left"
  when :out
    left[name] = 0
    winner = name
    out << "#{name} checks out with #{result[1]}"
  else
    left[name] = cur
    out << "#{name} scores #{total}, #{cur} left"
  end
end

out << "STANDINGS"
names.each_with_index.sort_by { |n, i| [left[n], i] }.each_with_index do |(n, _), r|
  avg = if darts[n] == 0
    "-"
  else
    x = Rational((start - left[n]) * 3, darts[n])
    c = (x * 100 + Rational(1, 2)).floor
    format("%d.%02d", c / 100, c % 100)
  end
  out << format("%d. %-10s %4d %3d %6s", r + 1, n, left[n], turns[n], avg)
end
out << (winner ? "winner: #{winner}" : "no winner")
puts out

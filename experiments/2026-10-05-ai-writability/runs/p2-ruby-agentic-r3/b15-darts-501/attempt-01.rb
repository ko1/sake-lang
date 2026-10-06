lines = $stdin.each_line.map(&:chomp)
h = lines.shift.to_s.split
ok = h.size.between?(2, 5) && h[0] =~ /\A\d+\z/ && h[0].to_i.between?(2, 1001) &&
     h[1..].all? { |x| x =~ /\A[a-z]{1,10}\z/ } && h[1..].uniq.size == h.size - 1
unless ok
  puts "invalid header"
  exit
end
start = h[0].to_i
names = h[1..]
left = names.to_h { |x| [x, start] }
turns = names.to_h { |x| [x, 0] }
darts = names.to_h { |x| [x, 0] }
winner = nil
def val(t)
  case t
  when /\A([SDT])(\d+)\z/
    n = $2.to_i
    return nil unless (1..20).cover?(n) && $2 !~ /\A0/
    [n * { "S" => 1, "D" => 2, "T" => 3 }[$1], $1 == "D"]
  when "25" then [25, false]
  when "BULL" then [50, true]
  when "MISS" then [0, false]
  end
end
out = []
lines.each_with_index do |l, i|
  n = i + 2
  next if l.strip.empty?
  f = l.split
  if winner
    out << "line #{n}: game over"; next
  end
  nm = f[0]
  unless left.key?(nm)
    out << "line #{n}: unknown player #{nm}"; next
  end
  ds = f[1..]
  unless ds.size.between?(1, 3)
    out << "line #{n}: expected 1 to 3 darts"; next
  end
  bad = ds.find { |d| val(d).nil? }
  if bad
    out << "line #{n}: bad dart #{bad}"; next
  end
  cur = left[nm]
  total = 0
  result = nil
  ds.each do |d|
    pts, dbl = val(d)
    darts[nm] += 1
    r = cur - pts
    if r < 0 || r == 1 || (r == 0 && !dbl)
      result = :bust; break
    elsif r == 0
      cur = 0; result = [:out, d]; break
    end
    cur = r; total += pts
  end
  turns[nm] += 1
  if result == :bust
    out << "#{nm} busts, #{left[nm]} left"
  elsif result
    left[nm] = 0; winner = nm
    out << "#{nm} checks out with #{result[1]}"
  else
    left[nm] = cur
    out << "#{nm} scores #{total}, #{cur} left"
  end
end
out << "STANDINGS"
names.each_with_index.sort_by { |x, i| [left[x], i] }.each_with_index do |(x, _), r|
  avg = if darts[x] == 0
    "-"
  else
    num = (start - left[x]) * 3 * 100
    c = (num * 2 + darts[x]) / (2 * darts[x])
    format("%d.%02d", c / 100, c % 100)
  end
  out << format("%d. %-10s %4d %3d %6s", r + 1, x, left[x], turns[x], avg)
end
out << (winner ? "winner: #{winner}" : "no winner")
puts out

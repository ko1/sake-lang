lines = $stdin.each_line.map(&:chomp)
h = lines[0] ? lines[0].split : []
ok = h.size >= 2 && h.size <= 5 && h[0] =~ /\A\d+\z/ && (2..1001).cover?(h[0].to_i) &&
     h[1..].all? { |x| x =~ /\A[a-z]{1,10}\z/ } && h[1..].uniq.size == h.size - 1
unless ok
  puts "invalid header"
  exit
end
start = h[0].to_i
names = h[1..]
left = names.to_h { |x| [x, start] }
turns = Hash.new(0)
darts = Hash.new(0)
winner = nil

def dart(t)
  if (m = /\A([SDT])([1-9]|1\d|20)\z/.match(t))
    mult = { "S" => 1, "D" => 2, "T" => 3 }[m[1]]
    [mult * m[2].to_i, m[1] == "D"]
  elsif t == "25" then [25, false]
  elsif t == "BULL" then [50, true]
  elsif t == "MISS" then [0, false]
  end
end

out = []
lines.each_with_index do |l, i|
  next if i == 0
  n = i + 1
  f = l.split
  next if f.empty?
  if winner
    out << "line #{n}: game over"
    next
  end
  nm = f[0]
  ds = f[1..]
  unless left.key?(nm)
    out << "line #{n}: unknown player #{nm}"
    next
  end
  unless (1..3).cover?(ds.size)
    out << "line #{n}: expected 1 to 3 darts"
    next
  end
  if (bad = ds.find { |d| dart(d).nil? })
    out << "line #{n}: bad dart #{bad}"
    next
  end
  cur = left[nm]
  total = 0
  result = nil
  ds.each do |d|
    pts, dbl = dart(d)
    darts[nm] += 1
    total += pts
    cur -= pts
    if cur < 0 || cur == 1 || (cur == 0 && !dbl)
      result = :bust
      break
    elsif cur == 0
      result = [:out, d]
      break
    end
  end
  turns[nm] += 1
  if result == :bust
    out << "#{nm} busts, #{left[nm]} left"
  elsif result
    left[nm] = 0
    winner = nm
    out << "#{nm} checks out with #{result[1]}"
  else
    left[nm] = cur
    out << "#{nm} scores #{total}, #{cur} left"
  end
end
puts out
puts "STANDINGS"
names.each_with_index.sort_by { |x, i| [left[x], i] }.each_with_index do |(x, _), r|
  avg = if darts[x] == 0
          "-"
        else
          q = Rational((start - left[x]) * 3, darts[x])
          c = (q * 100 + Rational(1, 2)).floor
          format("%d.%02d", c / 100, c % 100)
        end
  puts format("%d. %-10s %4d %3d %6s", r + 1, x, left[x], turns[x], avg)
end
puts winner ? "winner: #{winner}" : "no winner"

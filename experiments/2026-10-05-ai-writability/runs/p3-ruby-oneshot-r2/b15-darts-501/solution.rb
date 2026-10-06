lines = $stdin.read.to_s.split("\n").map { |l| l.chomp("\r") }
h = (lines[0] || "").split
start = h[0]
names = h[1..] || []
unless start && start =~ /\A\d+\z/ && (2..1001).cover?(start.to_i) &&
       (1..4).cover?(names.size) && names.all? { |x| x =~ /\A[a-z]{1,10}\z/ } &&
       names.uniq.size == names.size
  puts "invalid header"
  exit
end
start = start.to_i
left = names.to_h { |x| [x, start] }
turns = names.to_h { |x| [x, 0] }
thrown = names.to_h { |x| [x, 0] }
winner = nil
out = []

def dart(t)
  case t
  when /\A([SDT])(\d+)\z/
    kind, digits = $1, $2
    num = digits.to_i
    return nil if digits.start_with?("0") || num < 1 || num > 20
    [num * { "S" => 1, "D" => 2, "T" => 3 }[kind], kind == "D"]
  when "25" then [25, false]
  when "BULL" then [50, true]
  when "MISS" then [0, false]
  end
end

lines.each_with_index do |raw, i|
  next if i == 0
  n = i + 1
  f = raw.split
  next if f.empty?
  name = f[0]
  ds = f[1..]
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
  bad = ds.find { |t| dart(t).nil? }
  if bad
    out << "line #{n}: bad dart #{bad}"
    next
  end
  cur = left[name]
  total = 0
  result = nil
  ds.each do |t|
    pts, dbl = dart(t)
    thrown[name] += 1
    total += pts
    nl = cur - pts
    if nl < 0 || nl == 1 || (nl == 0 && !dbl)
      result = :bust
      break
    elsif nl == 0
      result = [:out, t]
      break
    end
    cur = nl
  end
  turns[name] += 1
  if result == :bust
    out << "#{name} busts, #{left[name]} left"
  elsif result
    left[name] = 0
    winner = name
    out << "#{name} checks out with #{result[1]}"
  else
    left[name] = cur
    out << "#{name} scores #{total}, #{cur} left"
  end
end

out << "STANDINGS"
names.each_with_index.sort_by { |x, i| [left[x], i] }.each_with_index do |(x, _), r|
  avg = thrown[x] == 0 ? "-" : format("%.2f", (start - left[x]) * 3.0 / thrown[x])
  out << format("%d. %-10s %4d %3d %6s", r + 1, x, left[x], turns[x], avg)
end
out << (winner ? "winner: #{winner}" : "no winner")
puts out

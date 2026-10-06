lines = $stdin.each_line.map(&:chomp)
h = (lines[0] || "").split
unless h.size.between?(2, 5) && h[0].match?(/\A\d+\z/) && h[0].to_i.between?(2, 1001) &&
       h[1..].all? { |x| x.match?(/\A[a-z]{1,10}\z/) } && h[1..].uniq.size == h.size - 1
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
  case t
  when /\A([SDT])([1-9]|1\d|20)\z/
    m = { "S" => 1, "D" => 2, "T" => 3 }[$1]
    [m * $2.to_i, $1 == "D"]
  when "25" then [25, false]
  when "BULL" then [50, true]
  when "MISS" then [0, false]
  end
end

out = []
lines.each_with_index do |raw, i|
  next if i == 0
  n = i + 1
  f = raw.split
  next if f.empty?
  name = f[0]
  ds = f[1..]
  if winner
    out << "line #{n}: game over"
  elsif !left.key?(name)
    out << "line #{n}: unknown player #{name}"
  elsif !ds.size.between?(1, 3)
    out << "line #{n}: expected 1 to 3 darts"
  elsif (bad = ds.find { |d| dart(d).nil? })
    out << "line #{n}: bad dart #{bad}"
  else
    turns[name] += 1
    cur = left[name]
    total = 0
    result = nil
    ds.each do |d|
      pts, dbl = dart(d)
      darts[name] += 1
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
end
out << "STANDINGS"
names.each_with_index.sort_by { |x, i| [left[x], i] }.each_with_index do |(x, _), r|
  avg = darts[x] == 0 ? "-" : format("%.2f", (start - left[x]) * 3.0 / darts[x])
  out << format("%d. %-10s %4d %3d %6s", r + 1, x, left[x], turns[x], avg)
end
out << (winner ? "winner: #{winner}" : "no winner")
puts out

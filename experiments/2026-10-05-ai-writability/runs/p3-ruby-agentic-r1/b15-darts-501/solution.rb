lines = $stdin.read.split("\n", -1)
h = (lines[0] || "").split
unless h.size >= 2 && h.size <= 5 && h[0] =~ /\A\d+\z/ && (2..1001).cover?(h[0].to_i) &&
       h[1..].all? { |x| x =~ /\A[a-z]{1,10}\z/ } && h[1..].uniq.size == h.size - 1
  puts "invalid header"; exit
end
start = h[0].to_i
names = h[1..]
left = names.to_h { |x| [x, start] }
turns = Hash.new(0)
darts = Hash.new(0)
winner = nil

val = lambda do |t|
  case t
  when /\A([SDT])([1-9]|1\d|20)\z/
    $1 == "S" ? [$2.to_i, false] : $1 == "D" ? [$2.to_i * 2, true] : [$2.to_i * 3, false]
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
  elsif ds.size < 1 || ds.size > 3
    out << "line #{n}: expected 1 to 3 darts"
  elsif (bad = ds.find { |t| val.(t).nil? })
    out << "line #{n}: bad dart #{bad}"
  else
    cur = left[name]
    total = 0
    result = nil
    ds.each do |t|
      pts, dbl = val.(t)
      darts[name] += 1
      total += pts
      cur -= pts
      if cur < 0 || cur == 1 || (cur == 0 && !dbl)
        result = :bust; break
      elsif cur == 0
        result = [:out, t]; break
      end
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
end
out << "STANDINGS"
names.each_with_index.sort_by { |x, i| [left[x], i] }.each_with_index do |(x, _), r|
  avg = "-"
  if darts[x] > 0
    c = ((Rational((start - left[x]) * 3, darts[x]) * 100) + Rational(1, 2)).floor
    avg = format("%d.%02d", c / 100, c % 100)
  end
  out << format("%d. %-10s %4d %3d %6s", r + 1, x, left[x], turns[x], avg)
end
out << (winner ? "winner: #{winner}" : "no winner")
puts out

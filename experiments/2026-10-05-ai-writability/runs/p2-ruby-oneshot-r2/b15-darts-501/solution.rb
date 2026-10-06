lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
hdr = (lines[0] || "").split
ok = hdr.size >= 2 && hdr.size <= 5 && hdr[0] =~ /\A\d+\z/ &&
     hdr[0].to_i >= 2 && hdr[0].to_i <= 1001 &&
     hdr[1..].all? { |s| s =~ /\A[a-z]{1,10}\z/ } && hdr[1..].uniq.size == hdr.size - 1
unless ok
  puts "invalid header"
  exit
end
start = hdr[0].to_i
names = hdr[1..]
left = names.to_h { |s| [s, start] }
turns = Hash.new(0)
thrown = Hash.new(0)
winner = nil
out = []

parse = lambda do |t|
  case t
  when "25" then [25, false]
  when "BULL" then [50, true]
  when "MISS" then [0, false]
  when /\A([SDT])(1[0-9]|20|[1-9])\z/
    k = $2.to_i
    case $1
    when "S" then [k, false]
    when "D" then [2 * k, true]
    else [3 * k, false]
    end
  end
end

lines.each_with_index do |raw, i|
  next if i == 0
  n = i + 1
  f = raw.split
  next if f.empty?
  name = f[0]
  darts = f[1..]
  if winner
    out << "line #{n}: game over"
    next
  end
  unless left.key?(name)
    out << "line #{n}: unknown player #{name}"
    next
  end
  if darts.size < 1 || darts.size > 3
    out << "line #{n}: expected 1 to 3 darts"
    next
  end
  bad = darts.find { |d| parse.call(d).nil? }
  if bad
    out << "line #{n}: bad dart #{bad}"
    next
  end
  cur = left[name]
  total = 0
  result = nil
  darts.each do |d|
    v, dbl = parse.call(d)
    thrown[name] += 1
    total += v
    nl = cur - v
    if nl < 0 || nl == 1 || (nl == 0 && !dbl)
      result = [:bust]
      break
    elsif nl == 0
      result = [:out, d]
      cur = 0
      break
    end
    cur = nl
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
order = names.each_with_index.sort_by { |s, i| [left[s], i] }.map(&:first)
order.each_with_index do |s, r|
  avg = thrown[s] > 0 ? format("%.2f", (start - left[s]) * 3.0 / thrown[s]) : "-"
  out << format("%d. %-10s %4d %3d %6s", r + 1, s, left[s], turns[s], avg)
end
out << (winner ? "winner: #{winner}" : "no winner")
puts out

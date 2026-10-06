lines = $stdin.each_line.map(&:chomp)
h = (lines[0] || "").split(/\s+/).reject(&:empty?)
names = h[1..] || []
unless h.size >= 2 && h[0] =~ /\A\d+\z/ && (2..1001).cover?(h[0].to_i) && names.size <= 4 &&
       names.all? { |n| n =~ /\A[a-z]{1,10}\z/ } && names.uniq.size == names.size
  puts "invalid header"
  exit
end
start = h[0].to_i
left = names.to_h { |n| [n, start] }
turns = Hash.new(0)
darts_thrown = Hash.new(0)
winner = nil

def value(d)
  case d
  when /\A([SDT])(\d+)\z/
    n = $2.to_i
    return nil unless (1..20).cover?(n) && $2 == n.to_s
    [n * { "S" => 1, "D" => 2, "T" => 3 }[$1], $1 == "D"]
  when "25" then [25, false]
  when "BULL" then [50, true]
  when "MISS" then [0, false]
  end
end

lines.each_with_index do |raw, i|
  next if i == 0
  no = i + 1
  f = raw.split(/\s+/).reject(&:empty?)
  next if f.empty?
  name = f[0]
  ds = f[1..]
  if winner
    puts "line #{no}: game over"
    next
  end
  unless left.key?(name)
    puts "line #{no}: unknown player #{name}"
    next
  end
  unless (1..3).cover?(ds.size)
    puts "line #{no}: expected 1 to 3 darts"
    next
  end
  bad = ds.find { |d| value(d).nil? }
  if bad
    puts "line #{no}: bad dart #{bad}"
    next
  end
  turns[name] += 1
  cur = left[name]
  total = 0
  result = nil
  ds.each do |d|
    pts, dbl = value(d)
    darts_thrown[name] += 1
    total += pts
    cur -= pts
    if cur < 0 || cur == 1 || (cur == 0 && !dbl)
      result = [:bust]
      break
    elsif cur == 0
      result = [:out, d]
      break
    end
  end
  case result&.first
  when :bust
    puts "#{name} busts, #{left[name]} left"
  when :out
    left[name] = 0
    winner = name
    puts "#{name} checks out with #{result[1]}"
  else
    left[name] = cur
    puts "#{name} scores #{total}, #{cur} left"
  end
end

puts "STANDINGS"
names.each_with_index.sort_by { |n, i| [left[n], i] }.each_with_index do |(n, _), r|
  avg =
    if darts_thrown[n] == 0 then "-"
    else
      c = ((start - left[n]) * 300 * 2 + darts_thrown[n]) / (2 * darts_thrown[n])
      format("%d.%02d", c / 100, c % 100)
    end
  puts format("%d. %-10s %4d %3d %6s", r + 1, n, left[n], turns[n], avg)
end
puts winner ? "winner: #{winner}" : "no winner"

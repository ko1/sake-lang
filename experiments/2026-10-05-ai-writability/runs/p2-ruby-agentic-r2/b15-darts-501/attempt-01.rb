lines = $stdin.each_line.map(&:chomp)
h = lines[0].to_s.split
start = h[0]
names = h[1..] || []
unless start =~ /\A\d+\z/ && (2..1001).cover?(start.to_i) && (1..4).cover?(names.size) &&
       names.all? { |x| x =~ /\A[a-z]{1,10}\z/ } && names.uniq.size == names.size
  puts "invalid header"
  exit
end
start = start.to_i

left = names.to_h { |x| [x, start] }
turns = Hash.new(0)
thrown = Hash.new(0)
winner = nil

value = lambda do |d|
  case d
  when "25" then [25, false]
  when "BULL" then [50, true]
  when "MISS" then [0, false]
  when /\A([SDT])([1-9]|1\d|20)\z/
    k = $1
    v = $2.to_i
    k == "S" ? [v, false] : k == "D" ? [2 * v, true] : [3 * v, false]
  end
end

(1...lines.size).each do |i|
  l = lines[i]
  n = i + 1
  next if l.strip.empty?
  f = l.split
  name = f[0]
  darts = f[1..]
  if winner
    puts "line #{n}: game over"
  elsif !left.key?(name)
    puts "line #{n}: unknown player #{name}"
  elsif darts.empty? || darts.size > 3
    puts "line #{n}: expected 1 to 3 darts"
  elsif (bad = darts.find { |d| value.call(d).nil? })
    puts "line #{n}: bad dart #{bad}"
  else
    cur = left[name]
    total = 0
    result = nil
    darts.each do |d|
      pts, dbl = value.call(d)
      thrown[name] += 1
      nxt = cur - pts
      if nxt < 0 || nxt == 1 || (nxt == 0 && !dbl)
        result = [:bust]
        break
      elsif nxt == 0
        result = [:out, d]
        cur = 0
        break
      end
      cur = nxt
      total += pts
    end
    turns[name] += 1
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
end

puts "STANDINGS"
names.each_with_index.sort_by { |x, i| [left[x], i] }.each_with_index do |(x, _), r|
  avg =
    if thrown[x] == 0
      "-"
    else
      c = ((Rational((start - left[x]) * 3, thrown[x]) * 100) + Rational(1, 2)).floor
      format("%d.%02d", c / 100, c % 100)
    end
  puts format("%d. %-10s %4d %3d %6s", r + 1, x, left[x], turns[x], avg)
end
puts winner ? "winner: #{winner}" : "no winner"

lines = STDIN.read.split("\n", -1)
lines.pop if lines.last == ''
h = lines[0] ? lines[0].split : []
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
turns = Hash.new(0)
thrown = Hash.new(0)
winner = nil

def dart(t)
  return [25, false] if t == '25'
  return [50, true] if t == 'BULL'
  return [0, false] if t == 'MISS'
  if t =~ /\A([STD])([1-9]|1\d|20)\z/
    m = { 'S' => 1, 'D' => 2, 'T' => 3 }[$1]
    return [m * $2.to_i, $1 == 'D']
  end
  nil
end

lines[1..].each_with_index do |raw, i|
  n = i + 2
  f = raw.split
  next if f.empty?
  name = f[0]
  ds = f[1..]
  if winner
    puts "line #{n}: game over"
  elsif !left.key?(name)
    puts "line #{n}: unknown player #{name}"
  elsif ds.size < 1 || ds.size > 3
    puts "line #{n}: expected 1 to 3 darts"
  elsif (bad = ds.find { |d| dart(d).nil? })
    puts "line #{n}: bad dart #{bad}"
  else
    cur = left[name]
    total = 0
    result = nil
    ds.each do |d|
      pts, dbl = dart(d)
      thrown[name] += 1
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
names.each_with_index.sort_by { |nm, i| [left[nm], i] }.each_with_index do |(nm, _), r|
  avg = thrown[nm] > 0 ? format("%.2f", (start - left[nm]) * 3.0 / thrown[nm]) : '-'
  puts format("%d. %-10s %4d %3d %6s", r + 1, nm, left[nm], turns[nm], avg)
end
puts winner ? "winner: #{winner}" : "no winner"

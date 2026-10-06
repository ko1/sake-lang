lines = $stdin.read.split("\n", -1).map { |l| l.chomp("\r") }
lines.pop if lines.last == ""
hf = (lines[0] || "").split(/\s+/).reject(&:empty?)
ok = hf.size >= 2 && hf.size <= 5 && hf[0] =~ /\A\d+\z/ && (2..1001).cover?(hf[0].to_i)
names = hf[1..] || []
ok &&= names.all? { |x| x =~ /\A[a-z]{1,10}\z/ } && names.uniq.size == names.size
unless ok
  puts "invalid header"
  exit
end
start = hf[0].to_i
left = {}
turns = Hash.new(0)
thrown = Hash.new(0)
names.each { |x| left[x] = start }
winner = nil
out = []

value = lambda do |t|
  if (m = /\A([SDT])(\d+)\z/.match(t)) && (1..20).cover?(m[2].to_i) && m[2] !~ /\A0/
    mult = { "S" => 1, "D" => 2, "T" => 3 }[m[1]]
    [mult * m[2].to_i, m[1] == "D"]
  elsif t == "25" then [25, false]
  elsif t == "BULL" then [50, true]
  elsif t == "MISS" then [0, false]
  end
end

lines[1..].each_with_index do |raw, i|
  n = i + 2
  line = raw.strip
  next if line.empty?
  f = line.split(/\s+/)
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
  unless (1..3).cover?(darts.size)
    out << "line #{n}: expected 1 to 3 darts"
    next
  end
  bad = darts.find { |d| value.call(d).nil? }
  if bad
    out << "line #{n}: bad dart #{bad}"
    next
  end
  turns[name] += 1
  cur = left[name]
  total = 0
  result = nil
  darts.each do |d|
    pts, dbl = value.call(d)
    thrown[name] += 1
    cur -= pts
    total += pts
    if cur < 0 || cur == 1 || (cur == 0 && !dbl)
      result = [:bust]
      break
    elsif cur == 0
      result = [:out, d]
      break
    end
  end
  if result && result[0] == :bust
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
order = names.each_with_index.sort_by { |x, i| [left[x], i] }.map(&:first)
order.each_with_index do |x, i|
  avg = if thrown[x] == 0
          "-"
        else
          r = Rational((start - left[x]) * 3 * 100, thrown[x]) + Rational(1, 2)
          t = r.floor
          "#{t / 100}.#{(t % 100).to_s.rjust(2, '0')}"
        end
  out << format("%d. %-10s %4d %3d %6s", i + 1, x, left[x], turns[x], avg)
end
out << (winner ? "winner: #{winner}" : "no winner")
puts out

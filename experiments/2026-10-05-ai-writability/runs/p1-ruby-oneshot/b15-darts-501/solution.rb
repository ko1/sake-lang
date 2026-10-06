lines = $stdin.each_line.map { |l| l.chomp }
hf = (lines[0] || "").split(/\s+/).reject(&:empty?)
start = hf[0]
names = hf[1..] || []
unless start && start =~ /\A\d+\z/ && (2..1001).cover?(start.to_i) &&
       (1..4).cover?(names.size) && names.all? { |s| s =~ /\A[a-z]{1,10}\z/ } &&
       names.uniq.size == names.size
  puts "invalid header"
  exit
end
start = start.to_i
st = {}
names.each { |nm| st[nm] = { left: start, turns: 0, darts: 0 } }
out = []
winner = nil

def parse_dart(t)
  case t
  when "25" then [25, false]
  when "BULL" then [50, true]
  when "MISS" then [0, false]
  when /\A([SDT])([1-9]|1\d|20)\z/
    k = $1
    v = $2.to_i
    [v * { "S" => 1, "D" => 2, "T" => 3 }[k], k == "D"]
  end
end

lines.each_with_index do |raw, i|
  next if i == 0
  n = i + 1
  f = raw.strip.split(/\s+/)
  next if f.empty?
  name = f[0]
  darts = f[1..]
  if winner
    out << "line #{n}: game over"
    next
  end
  unless st[name]
    out << "line #{n}: unknown player #{name}"
    next
  end
  unless (1..3).cover?(darts.size)
    out << "line #{n}: expected 1 to 3 darts"
    next
  end
  bad = darts.find { |d| parse_dart(d).nil? }
  if bad
    out << "line #{n}: bad dart #{bad}"
    next
  end
  p = st[name]
  left = p[:left]
  total = 0
  result = nil
  darts.each do |d|
    pts, dbl = parse_dart(d)
    p[:darts] += 1
    total += pts
    left -= pts
    if left < 0 || left == 1 || (left == 0 && !dbl)
      result = [:bust]
      break
    elsif left == 0
      result = [:out, d]
      break
    end
  end
  p[:turns] += 1
  case result&.first
  when :bust
    out << "#{name} busts, #{p[:left]} left"
  when :out
    p[:left] = 0
    winner = name
    out << "#{name} checks out with #{result[1]}"
  else
    p[:left] = left
    out << "#{name} scores #{total}, #{left} left"
  end
end

out << "STANDINGS"
names.each_with_index.sort_by { |nm, i| [st[nm][:left], i] }.each_with_index do |(nm, _), r|
  p = st[nm]
  avg =
    if p[:darts] == 0
      "-"
    else
      num = (start - p[:left]) * 3 * 100
      den = p[:darts]
      c = (2 * num + den) / (2 * den)
      format("%d.%02d", c / 100, c % 100)
    end
  out << format("%d. %-10s %4d %3d %6s", r + 1, nm, p[:left], p[:turns], avg)
end
out << (winner ? "winner: #{winner}" : "no winner")
puts out

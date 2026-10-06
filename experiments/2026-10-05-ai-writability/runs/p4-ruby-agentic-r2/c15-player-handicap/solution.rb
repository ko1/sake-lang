Player = Struct.new(:name, :index, :left, :turns, :darts, :start, :handicap)

MULT = { "S" => 1, "D" => 2, "T" => 3 }.freeze

# [points, double?] or nil for a bad token
def dart_value(tok)
  return [0, false] if tok == "MISS"
  return [25, false] if tok == "25"
  return [50, true] if tok == "BULL"
  m = /\A([SDT])([1-9]|1[0-9]|20)\z/.match(tok)
  return nil unless m
  [MULT[m[1]] * m[2].to_i, m[1] == "D"]
end

def valid_header?(words)
  return false unless words.size.between?(2, 5) && words[0].match?(/\A\d+\z/)
  return false unless words[0].to_i.between?(2, 1001)
  fields = words[1..].map { _1.split(":", -1) }
  return false unless fields.all? do |f|
    f.size == 1 || (f.size == 2 && f[1].match?(/\A\d+\z/) && f[1].to_i.between?(2, 1001))
  end
  names = fields.map(&:first)
  names.all? { _1.match?(/\A[a-z]{1,10}\z/) } && names.uniq.size == names.size
end

lines = $stdin.read.split("\n")
header = (lines[0] || "").split
unless valid_header?(header)
  puts "invalid header"
  exit
end
start = header[0].to_i
players = {}
header[1..].each_with_index do |fld, i|
  n, hs = fld.split(":", -1)
  st = hs ? hs.to_i : start
  players[n] = Player.new(n, i, st, 0, 0, st, !hs.nil?)
end
winner = nil

lines.each_with_index do |line, i|
  next if i == 0
  words = line.split
  next if words.empty?
  no = i + 1
  if winner
    puts "line #{no}: game over"
    next
  end
  pl = players[words[0]]
  unless pl
    puts "line #{no}: unknown player #{words[0]}"
    next
  end
  darts = words[1..]
  unless darts.size.between?(1, 3)
    puts "line #{no}: expected 1 to 3 darts"
    next
  end
  values = darts.map { dart_value(_1) }
  bad = values.index(nil)
  if bad
    puts "line #{no}: bad dart #{darts[bad]}"
    next
  end
  pl.turns += 1
  rem = pl.left
  result = :open
  values.each_with_index do |(pts, dbl), k|
    pl.darts += 1
    rem -= pts
    if rem < 0 || rem == 1 || (rem == 0 && !dbl)
      result = :bust
      break
    elsif rem == 0
      result = darts[k]
      break
    end
  end
  case result
  when :bust
    puts "#{pl.name} busts, #{pl.left} left"
  when :open
    puts "#{pl.name} scores #{pl.left - rem}, #{rem} left"
    pl.left = rem
  else
    pl.left = 0
    winner = pl
    puts "#{pl.name} checks out with #{result}"
  end
end

puts "STANDINGS"
players.values.sort_by { [_1.left, -_1.start, _1.index] }.each_with_index do |pl, r|
  avg = pl.darts > 0 ? format("%.2f", (pl.start - pl.left) * 3.0 / pl.darts) : "-"
  puts format("%d. %-10s %4d %3d %6s", r + 1, pl.name, pl.left, pl.turns, avg) + (pl.handicap ? " (start #{pl.start})" : "")
end
puts winner ? "winner: #{winner.name}" : "no winner"

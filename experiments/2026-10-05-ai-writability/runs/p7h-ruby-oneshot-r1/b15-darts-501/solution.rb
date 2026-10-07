def parse_dart(dart)
  if dart == 'MISS'
    return 0
  elsif dart == '25'
    return 25
  elsif dart == 'BULL'
    return [:bull, 50]
  elsif dart =~ /^S(\d+)$/
    num = $1.to_i
    return num if num >= 1 && num <= 20
  elsif dart =~ /^D(\d+)$/
    num = $1.to_i
    return [:double, num * 2] if num >= 1 && num <= 20
  elsif dart =~ /^T(\d+)$/
    num = $1.to_i
    return num * 3 if num >= 1 && num <= 20
  end
  nil
end

first_line = STDIN.readline.chomp
parts = first_line.split

if parts.length < 2 || parts.length > 5
  puts "invalid header"
  exit
end

start = parts[0]
if start !~ /^\d+$/ || start.to_i < 2 || start.to_i > 1001
  puts "invalid header"
  exit
end
start = start.to_i

players = parts[1..-1]
if players.length < 1 || players.length > 4 || players.any? { |p| p !~ /^[a-z]{1,10}$/ } || players.uniq.length != players.length
  puts "invalid header"
  exit
end

points = {}
turns_played = {}
darts_thrown = {}
checked_out = {}

players.each do |p|
  points[p] = start
  turns_played[p] = 0
  darts_thrown[p] = 0
  checked_out[p] = false
end

line_num = 1

while true
  line_num += 1
  begin
    line = STDIN.readline.chomp
  rescue EOFError
    break
  end

  if line.strip.empty?
    next
  end

  parts = line.split

  if parts.length < 1
    next
  end

  name = parts[0]
  darts = parts[1..-1]

  if checked_out.any? { |_, v| v }
    puts "line #{line_num}: game over"
    next
  end

  if !players.include?(name)
    puts "line #{line_num}: unknown player #{name}"
    next
  end

  if darts.length < 1 || darts.length > 3
    puts "line #{line_num}: expected 1 to 3 darts"
    next
  end

  parsed_darts = []
  valid = true
  last_dart = nil

  darts.each do |dart|
    parsed = parse_dart(dart)
    if parsed.nil?
      puts "line #{line_num}: bad dart #{dart}"
      valid = false
      break
    end
    parsed_darts << parsed
    last_dart = parsed
  end

  next if !valid

  old_points = points[name]
  score = 0
  is_double = false
  bust = false
  checkout = false

  parsed_darts.each do |dart|
    if dart.is_a?(Array)
      if dart[0] == :double
        score += dart[1]
        is_double = true
      elsif dart[0] == :bull
        score += dart[1]
        is_double = true
      end
    else
      score += dart
    end

    new_points = old_points - score

    if new_points < 0 || new_points == 1 || (new_points == 0 && !is_double)
      bust = true
      break
    end

    if new_points == 0 && is_double
      checkout = true
      break
    end
  end

  if bust
    puts "#{name} busts, #{old_points} left"
  elsif checkout
    points[name] = 0
    darts_thrown[name] += parsed_darts.length
    turns_played[name] += 1
    checked_out[name] = true
    last_dart_str = if parsed_darts[-1].is_a?(Array)
      if parsed_darts[-1][0] == :double
        "D#{parsed_darts[-1][1] / 2}"
      elsif parsed_darts[-1][0] == :bull
        "BULL"
      end
    else
      dart = darts[-1]
      dart
    end
    puts "#{name} checks out with #{last_dart_str}"
  else
    new_points = old_points - score
    points[name] = new_points
    darts_thrown[name] += parsed_darts.length
    turns_played[name] += 1
    puts "#{name} scores #{score}, #{new_points} left"
  end
end

puts "STANDINGS"

sorted = players.sort_by { |p| [points[p], players.index(p)] }

sorted.each_with_index do |p, idx|
  rank = idx + 1
  left = points[p]
  turns = turns_played[p]

  if darts_thrown[p] == 0
    avg_str = "-"
  else
    avg = (start - left) * 3.0 / darts_thrown[p]
    avg_str = format("%.2f", avg)
  end

  puts format("%d. %-10s %4d %3d %6s", rank, p, left, turns, avg_str)
end

winner = players.find { |p| checked_out[p] }
if winner
  puts "winner: #{winner}"
else
  puts "no winner"
end

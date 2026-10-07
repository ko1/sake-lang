header_line = STDIN.readline.strip

if header_line.empty?
  puts "invalid header"
  exit
end

parts = header_line.split
if parts.length < 2 || parts.length > 5
  puts "invalid header"
  exit
end

start_score = parts[0]
if start_score !~ /^\d+$/ || start_score.to_i < 2 || start_score.to_i > 1001
  puts "invalid header"
  exit
end

start = start_score.to_i
players = parts[1..-1]

if players.empty? || players.length > 4
  puts "invalid header"
  exit
end

players.each do |name|
  if name.empty? || name.length > 10 || name !~ /^[a-z]+$/
    puts "invalid header"
    exit
  end
end

# Check for duplicates
if players.uniq.length != players.length
  puts "invalid header"
  exit
end

# Initialize player state
player_state = {}
players.each do |name|
  player_state[name] = {
    points: start,
    turns: 0,
    darts_thrown: 0,
    checked_out: false
  }
end

def parse_dart(dart_str)
  if dart_str == "MISS"
    return { value: 0, is_double: false }
  elsif dart_str == "25"
    return { value: 25, is_double: false }
  elsif dart_str == "BULL"
    return { value: 50, is_double: true }
  elsif dart_str =~ /^[SDT](\d+)$/
    type = dart_str[0]
    num = $1.to_i

    if num < 1 || num > 20
      return nil
    end

    multiplier = case type
                 when 'S'
                   1
                 when 'D'
                   2
                 when 'T'
                   3
                 end

    is_double = (type == 'D')
    return { value: num * multiplier, is_double: is_double }
  else
    return nil
  end
end

line_num = 2
while true
  line = begin
    STDIN.readline.strip
  rescue EOFError
    break
  end

  next if line.empty?

  fields = line.split

  if fields.empty?
    line_num += 1
    next
  end

  player_name = fields[0]
  darts = fields[1..-1]

  # Check if game is over
  if player_state.values.any? { |s| s[:checked_out] }
    puts "line #{line_num}: game over"
    line_num += 1
    next
  end

  # Check if player exists
  if !player_state[player_name]
    puts "line #{line_num}: unknown player #{player_name}"
    line_num += 1
    next
  end

  # Check dart count
  if darts.length < 1 || darts.length > 3
    puts "line #{line_num}: expected 1 to 3 darts"
    line_num += 1
    next
  end

  # Parse darts
  parsed_darts = []
  invalid_dart = nil
  darts.each do |dart_str|
    parsed = parse_dart(dart_str)
    if !parsed
      invalid_dart = dart_str
      break
    end
    parsed_darts << parsed
  end

  if invalid_dart
    puts "line #{line_num}: bad dart #{invalid_dart}"
    line_num += 1
    next
  end

  # Apply darts
  turn_start_points = player_state[player_name][:points]
  current_points = turn_start_points
  turn_score = 0
  last_dart = nil
  busted = false
  checked_out = false
  darts_in_turn = 0

  parsed_darts.each do |dart|
    darts_in_turn += 1
    current_points -= dart[:value]
    turn_score += dart[:value]
    last_dart = dart

    # Check for bust
    if current_points < 0 || current_points == 1
      busted = true
      break
    elsif current_points == 0
      if !dart[:is_double]
        busted = true
        break
      else
        # Checkout
        checked_out = true
        break
      end
    end
  end

  # Update state
  if busted
    puts "#{player_name} busts, #{turn_start_points} left"
    player_state[player_name][:turns] += 1
    player_state[player_name][:darts_thrown] += darts_in_turn
  elsif checked_out
    player_state[player_name][:points] = current_points
    player_state[player_name][:turns] += 1
    player_state[player_name][:darts_thrown] += darts_in_turn
    player_state[player_name][:checked_out] = true

    if last_dart[:value] == 50
      dart_str = "BULL"
    else
      dart_str = "D#{last_dart[:value] / 2}"
    end

    puts "#{player_name} checks out with #{dart_str}"
  else
    player_state[player_name][:points] = current_points
    player_state[player_name][:turns] += 1
    player_state[player_name][:darts_thrown] += darts_in_turn
    puts "#{player_name} scores #{turn_score}, #{current_points} left"
  end

  line_num += 1
end

# Output standings
puts "STANDINGS"

# Sort by points left, then by header order
sorted = players.sort_by { |name|
  [player_state[name][:points], players.index(name)]
}

sorted.each_with_index do |name, rank|
  state = player_state[name]
  points_left = state[:points]
  turns = state[:turns]
  darts_thrown = state[:darts_thrown]

  if darts_thrown == 0
    avg = "-"
  else
    score_earned = start - points_left
    avg = sprintf("%.2f", (score_earned * 3.0 / darts_thrown))
  end

  puts sprintf("%d. %-10s %4d %3d %6s", rank + 1, name, points_left, turns, avg)
end

# Determine winner
winner = players.find { |name| player_state[name][:checked_out] }
if winner
  puts "winner: #{winner}"
else
  puts "no winner"
end

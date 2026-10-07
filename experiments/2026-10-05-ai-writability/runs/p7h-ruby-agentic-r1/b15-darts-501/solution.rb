#!/usr/bin/env ruby

lines = STDIN.readlines
header_line = lines[0].strip
parts = header_line.split

if parts.length < 2 || parts.length > 5
  puts "invalid header"
  exit
end

start_str = parts[0]
if start_str !~ /^\d+$/ || start_str.to_i < 2 || start_str.to_i > 1001
  puts "invalid header"
  exit
end

start = start_str.to_i
names = parts[1..-1]

if names.length < 1 || names.length > 4
  puts "invalid header"
  exit
end

if names.uniq.length != names.length
  puts "invalid header"
  exit
end

names.each do |name|
  if name !~ /^[a-z]{1,10}$/
    puts "invalid header"
    exit
  end
end

# Parse darts
def parse_dart(token)
  case token
  when /^S([1-9]|1[0-9]|20)$/
    return $1.to_i
  when /^D([1-9]|1[0-9]|20)$/
    return $1.to_i * 2
  when /^T([1-9]|1[0-9]|20)$/
    return $1.to_i * 3
  when "25"
    return 25
  when "BULL"
    return 50
  when "MISS"
    return 0
  else
    return nil
  end
end

def is_double(token)
  case token
  when /^D([1-9]|1[0-9]|20)$/
    return true
  when "BULL"
    return true
  else
    return false
  end
end

# Initialize game state
points = {}
turns = {}
darts_thrown = {}
checked_out = Set.new

names.each do |name|
  points[name] = start
  turns[name] = 0
  darts_thrown[name] = 0
end

# Process turns
lines[1..-1].each_with_index do |line, idx|
  line_num = idx + 2  # 1-based, skip header
  trimmed = line.strip
  next if trimmed.empty?

  turn_parts = trimmed.split

  # Check if game is over
  if checked_out.any?
    puts "line #{line_num}: game over"
    next
  end

  if turn_parts.length < 1
    puts "line #{line_num}: bad query"
    next
  end

  player = turn_parts[0]

  # Check if player is known
  if !names.include?(player)
    puts "line #{line_num}: unknown player #{player}"
    next
  end

  # Check if number of darts is 1-3
  dart_tokens = turn_parts[1..-1]
  if dart_tokens.length < 1 || dart_tokens.length > 3
    puts "line #{line_num}: expected 1 to 3 darts"
    next
  end

  # Parse and validate darts
  darts = []
  dart_tokens.each do |token|
    value = parse_dart(token)
    if value.nil?
      puts "line #{line_num}: bad dart #{token}"
      break
    end
    darts << [value, is_double(token), token]
  end

  if darts.length != dart_tokens.length
    next
  end

  # Apply darts
  start_points = points[player]
  score = 0
  is_bust = false
  checkout_dart = nil

  darts.each do |value, is_dbl, token|
    new_points = points[player] - value
    score += value

    if new_points < 0 || new_points == 1
      # Bust
      is_bust = true
      break
    elsif new_points == 0
      if is_dbl
        # Checkout
        checkout_dart = token
        points[player] = 0
        break
      else
        # Bust
        is_bust = true
        break
      end
    else
      points[player] = new_points
    end
  end

  # Handle bust or checkout
  if is_bust
    puts "#{player} busts, #{start_points} left"
    points[player] = start_points
    turns[player] += 1
    darts_thrown[player] += darts.length
  elsif checkout_dart
    puts "#{player} checks out with #{checkout_dart}"
    turns[player] += 1
    darts_thrown[player] += darts.length
    checked_out.add(player)
  else
    puts "#{player} scores #{score}, #{points[player]} left"
    turns[player] += 1
    darts_thrown[player] += darts.length
  end
end

# Print standings
puts "STANDINGS"
sorted_players = names.sort_by { |name| [points[name], names.index(name)] }

sorted_players.each_with_index do |name, idx|
  rank = idx + 1
  pts = points[name]
  turns_count = turns[name]

  if darts_thrown[name] == 0
    avg = "-"
  else
    avg_val = (start - pts).to_f * 3 / darts_thrown[name]
    avg = format("%.2f", avg_val)
  end

  printf("%d. %-10s %4d %3d %6s\n", rank, name, pts, turns_count, avg)
end

# Print winner
if checked_out.any?
  winner = checked_out.to_a.sort_by { |name| [names.index(name)] }.first
  puts "winner: #{winner}"
else
  puts "no winner"
end

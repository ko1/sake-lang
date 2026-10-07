#!/usr/bin/env ruby

# Read input
lines = STDIN.readlines.map(&:strip)

# Parse header
header = lines[0].split
if header.length < 2 || header.length > 5
  puts "invalid header"
  exit
end

start_str = header[0]
unless start_str.match?(/^\d+$/)
  puts "invalid header"
  exit
end

start = start_str.to_i
if start < 2 || start > 1001
  puts "invalid header"
  exit
end

players = header[1..-1]
if players.length < 1 || players.length > 4
  puts "invalid header"
  exit
end

if players.any? { |p| !p.match?(/^[a-z]{1,10}$/) } || players.uniq.length != players.length
  puts "invalid header"
  exit
end

# Initialize player state
player_state = {}
player_order = []
players.each do |name|
  player_state[name] = {
    points: start,
    checked_out: false,
    turns: 0,
    darts_thrown: 0
  }
  player_order << name
end

# Parse dart value
def parse_dart(dart_str)
  if dart_str == "MISS"
    return { valid: true, points: 0, is_double: false }
  elsif dart_str == "BULL"
    return { valid: true, points: 50, is_double: true }
  elsif dart_str == "25"
    return { valid: true, points: 25, is_double: false }
  elsif dart_str.match?(/^S(\d+)$/)
    num = dart_str[1..-1].to_i
    if num >= 1 && num <= 20
      return { valid: true, points: num, is_double: false }
    else
      return { valid: false }
    end
  elsif dart_str.match?(/^D(\d+)$/)
    num = dart_str[1..-1].to_i
    if num >= 1 && num <= 20
      return { valid: true, points: num * 2, is_double: true }
    else
      return { valid: false }
    end
  elsif dart_str.match?(/^T(\d+)$/)
    num = dart_str[1..-1].to_i
    if num >= 1 && num <= 20
      return { valid: true, points: num * 3, is_double: false }
    else
      return { valid: false }
    end
  else
    return { valid: false }
  end
end

# Process turns
lines[1..-1].each_with_index do |line, idx|
  line_num = idx + 2
  line = line.strip

  # Skip blank lines
  if line.empty?
    next
  end

  fields = line.split
  if fields.empty?
    next
  end

  player_name = fields[0]
  dart_strs = fields[1..-1]

  # Check if game is over
  if player_state.any? { |_, state| state[:checked_out] }
    puts "line #{line_num}: game over"
    next
  end

  # Check if player is known
  if !player_state.key?(player_name)
    puts "line #{line_num}: unknown player #{player_name}"
    next
  end

  # Check if 1-3 darts
  if dart_strs.length < 1 || dart_strs.length > 3
    puts "line #{line_num}: expected 1 to 3 darts"
    next
  end

  # Parse darts
  darts = []
  invalid_dart = nil
  dart_strs.each do |dart_str|
    parsed = parse_dart(dart_str)
    if !parsed[:valid]
      invalid_dart = dart_str
      break
    end
    darts << parsed
  end

  if invalid_dart
    puts "line #{line_num}: bad dart #{invalid_dart}"
    next
  end

  # Apply darts
  start_points = player_state[player_name][:points]
  current_points = start_points
  turn_score = 0
  last_dart = nil

  darts.each do |dart|
    current_points -= dart[:points]

    if current_points < 0
      # Bust
      current_points = start_points
      puts "#{player_name} busts, #{current_points} left"
      player_state[player_name][:points] = current_points
      player_state[player_name][:turns] += 1
      break
    elsif current_points == 1
      # Bust
      current_points = start_points
      puts "#{player_name} busts, #{current_points} left"
      player_state[player_name][:points] = current_points
      player_state[player_name][:turns] += 1
      break
    elsif current_points == 0 && !dart[:is_double]
      # Bust
      current_points = start_points
      puts "#{player_name} busts, #{current_points} left"
      player_state[player_name][:points] = current_points
      player_state[player_name][:turns] += 1
      break
    elsif current_points == 0 && dart[:is_double]
      # Checkout
      puts "#{player_name} checks out with #{dart_str}"
      player_state[player_name][:points] = 0
      player_state[player_name][:checked_out] = true
      player_state[player_name][:turns] += 1
      player_state[player_name][:darts_thrown] += 1
      break
    else
      # Valid dart
      turn_score += dart[:points]
      player_state[player_name][:darts_thrown] += 1
      last_dart = dart_str
    end
  end

  # If not busted and not checked out, print scores
  if current_points > 0 && !player_state[player_name][:checked_out]
    player_state[player_name][:points] = current_points
    player_state[player_name][:turns] += 1
    puts "#{player_name} scores #{turn_score}, #{current_points} left"
  end
end

# Print standings
puts "STANDINGS"

# Sort players
sorted = player_order.map { |name|
  [player_state[name][:points], name]
}.sort_by { |points, _| points }

sorted.each_with_index do |(points, name), idx|
  rank = idx + 1
  turns = player_state[name][:turns]
  darts = player_state[name][:darts_thrown]

  if darts == 0
    avg = "-"
  else
    avg_val = (start - points).to_f * 3 / darts
    avg = format("%.2f", avg_val)
  end

  puts format("%d. %-10s %4d %3d %6s", rank, name, points, turns, avg)
end

# Print winner
winner = player_state.find { |_, state| state[:checked_out] }
if winner
  puts "winner: #{winner[0]}"
else
  puts "no winner"
end

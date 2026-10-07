#!/usr/bin/env ruby

def format_money(cents)
  dollars = cents / 100
  remainder = cents % 100
  sprintf("%.2f", cents / 100.0)
end

def calculate_fee(minutes, first, step, cap, grace)
  if minutes <= grace
    return 0
  end

  # Calculate full days (1440 minutes per day)
  full_days = minutes / 1440
  remainder = minutes % 1440

  if remainder == 0
    # Exactly full days
    return full_days * cap
  end

  # Calculate fee for remainder
  if remainder <= 60
    part_fee = first
  else
    minutes_after_first_hour = remainder - 60
    # Number of started 30-minute periods
    periods = (minutes_after_first_hour + 29) / 30  # ceiling division
    part_fee = first + step * periods
  end

  return full_days * cap + [part_fee, cap].min
end

# Parse header
header = gets.chomp
parts = header.split
first, step, cap, grace = parts[1..4].map(&:to_i)

inside = {}  # plate => [hour, minute, day]
exits = {}   # plate => []

current_day = 0
last_time = nil
line_num = 1

while line = gets
  line_num += 1
  line = line.chomp
  next if line.strip.empty?

  parts = line.split

  # Validate format
  if parts.length != 3 || !parts[0].match?(/^\d{2}:\d{2}$/) || !["IN", "OUT"].include?(parts[1]) || !parts[2].match?(/^[A-Z0-9]{1,8}$/)
    puts "line #{line_num}: invalid"
    next
  end

  time_str, action, plate = parts
  hour, minute = time_str.split(":").map(&:to_i)

  # Check for day change
  if last_time && [hour, minute] < last_time
    current_day += 1
  end
  last_time = [hour, minute]

  # Process action
  if action == "IN"
    if inside[plate]
      puts "line #{line_num}: #{plate} already inside"
    else
      inside[plate] = [hour, minute, current_day]
    end
  else  # OUT
    if !inside[plate]
      puts "line #{line_num}: #{plate} not inside"
    else
      in_hour, in_minute, in_day = inside[plate]

      # Calculate stay duration in minutes
      in_minutes_total = in_day * 1440 + in_hour * 60 + in_minute
      out_minutes_total = current_day * 1440 + hour * 60 + minute
      stay_minutes = out_minutes_total - in_minutes_total

      # Calculate fee
      fee_cents = calculate_fee(stay_minutes, first, step, cap, grace)
      fee_dollars = format_money(fee_cents)

      # Calculate display time
      stay_hours = stay_minutes / 60
      stay_mins = stay_minutes % 60

      puts "#{plate} #{stay_hours}:#{stay_mins.to_s.rjust(2, '0')} #{fee_dollars}"

      # Record exit
      exits[plate] ||= []
      exits[plate] << { fee: fee_cents, time_str: "#{stay_hours}:#{stay_mins.to_s.rjust(2, '0')}" }

      inside.delete(plate)
    end
  end
end

# Summary
puts "--- summary"

if exits.empty?
  puts "total 0 0.00"
else
  # Sort by revenue descending, then plate ascending
  sorted_plates = exits.keys.sort_by { |plate| [-exits[plate].sum { |e| e[:fee] }, plate] }

  total_exits = 0
  total_revenue = 0

  sorted_plates.each do |plate|
    exits_count = exits[plate].length
    revenue = exits[plate].sum { |e| e[:fee] }
    total_exits += exits_count
    total_revenue += revenue

    printf "%s %d %.2f\n", plate, exits_count, revenue / 100.0
  end

  printf "total %d %.2f\n", total_exits, total_revenue / 100.0
end

# Inside summary
if inside.empty?
  puts "inside: none"
else
  inside_plates = inside.keys.sort
  puts "inside: #{inside_plates.join(", ")}"
end

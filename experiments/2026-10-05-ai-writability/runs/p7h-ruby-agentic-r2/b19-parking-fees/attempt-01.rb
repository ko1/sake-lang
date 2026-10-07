#!/usr/bin/env ruby

# Parse rate header
rate_line = gets.chomp
rate_parts = rate_line.split
if rate_parts.size != 5 || rate_parts[0] != "RATE"
  puts "error: invalid rate header"
  exit
end

first, step_fee, cap, grace = rate_parts[1..4].map(&:to_i)

# Process events
inside = {}  # plate -> (day, hour, minute)
exits = {}   # plate -> [list of (duration, fee)]
errors = []
current_time = [0, 0, 0]  # [day, hour, minute]
line_num = 1

while (line = gets)
  line_num += 1
  stripped = line.chomp
  next if stripped.match?(/^\s*$/)

  parts = stripped.split
  if parts.size != 3
    errors << "line #{line_num}: invalid"
    next
  end

  time_str, action, plate = parts

  # Validate time format
  unless time_str.match?(/^\d{2}:\d{2}$/)
    errors << "line #{line_num}: invalid"
    next
  end

  hour = time_str[0..1].to_i
  minute = time_str[3..4].to_i

  if hour > 23 || minute > 59
    errors << "line #{line_num}: invalid"
    next
  end

  # Validate action
  unless action == "IN" || action == "OUT"
    errors << "line #{line_num}: invalid"
    next
  end

  # Validate plate
  unless plate.match?(/^[A-Z0-9]{1,8}$/)
    errors << "line #{line_num}: invalid"
    next
  end

  # Check for day change
  if hour * 60 + minute < current_time[1] * 60 + current_time[2]
    current_time[0] += 1
  end
  current_time[1] = hour
  current_time[2] = minute

  if action == "IN"
    if inside.key?(plate)
      errors << "line #{line_num}: #{plate} already inside"
    else
      inside[plate] = [current_time[0], hour, minute]
    end
  else  # OUT
    if !inside.key?(plate)
      errors << "line #{line_num}: #{plate} not inside"
    else
      in_day, in_hour, in_minute = inside[plate]

      # Calculate duration
      total_in_minutes = in_day * 1440 + in_hour * 60 + in_minute
      total_out_minutes = current_time[0] * 1440 + hour * 60 + minute
      duration = total_out_minutes - total_in_minutes

      # Calculate fee
      if duration <= grace
        fee = 0
      else
        days = duration / 1440
        remainder = duration % 1440

        if remainder <= 60
          part_fee = first
        else
          part_fee = first + step_fee * ((remainder - 60 + 29) / 30)  # ceil division
        end

        fee = days * cap + [cap, part_fee].min
      end

      # Print fee
      hours = duration / 60
      minutes = duration % 60
      fee_str = format("%.2f", fee / 100.0)
      puts "#{plate} #{hours}:#{minutes.to_s.rjust(2, '0')} #{fee_str}"

      # Track exits
      exits[plate] ||= []
      exits[plate] << fee

      inside.delete(plate)
    end
  end
end

errors.each { |e| puts e }

# Print summary
puts "--- summary"

# Sort by revenue descending, plate ascending
sorted_plates = exits.keys.sort_by { |plate| [-exits[plate].sum, plate] }

total_exits = 0
total_revenue = 0

sorted_plates.each do |plate|
  rev = exits[plate].sum
  count = exits[plate].size
  total_exits += count
  total_revenue += rev
  rev_str = format("%.2f", rev / 100.0)
  puts "#{plate} #{count} #{rev_str}"
end

total_rev_str = format("%.2f", total_revenue / 100.0)
puts "total #{total_exits} #{total_rev_str}"

# Print still inside
if inside.empty?
  puts "inside: none"
else
  plates = inside.keys.sort
  puts "inside: #{plates.join(', ')}"
end

#!/usr/bin/env ruby

rate_line = gets.chomp
rate_parts = rate_line.split
if rate_parts.size != 5 || rate_parts[0] != "RATE"
  puts "error: invalid rate header"
  exit
end

first, step_fee, cap, grace = rate_parts[1..4].map(&:to_i)

inside = {}
exits = {}
current_time = [0, 0, 0]
line_num = 1

while (line = gets)
  line_num += 1
  stripped = line.chomp
  next if stripped.match?(/^\s*$/)

  parts = stripped.split
  if parts.size != 3
    puts "line #{line_num}: invalid"
    next
  end

  time_str, action, plate = parts

  unless time_str.match?(/^\d{2}:\d{2}$/)
    puts "line #{line_num}: invalid"
    next
  end

  hour = time_str[0..1].to_i
  minute = time_str[3..4].to_i

  if hour > 23 || minute > 59
    puts "line #{line_num}: invalid"
    next
  end

  unless action == "IN" || action == "OUT"
    puts "line #{line_num}: invalid"
    next
  end

  unless plate.match?(/^[A-Z0-9]{1,8}$/)
    puts "line #{line_num}: invalid"
    next
  end

  if hour * 60 + minute < current_time[1] * 60 + current_time[2]
    current_time[0] += 1
  end
  current_time[1] = hour
  current_time[2] = minute

  if action == "IN"
    if inside.key?(plate)
      puts "line #{line_num}: #{plate} already inside"
    else
      inside[plate] = [current_time[0], hour, minute]
    end
  else
    if !inside.key?(plate)
      puts "line #{line_num}: #{plate} not inside"
    else
      in_day, in_hour, in_minute = inside[plate]

      total_in_minutes = in_day * 1440 + in_hour * 60 + in_minute
      total_out_minutes = current_time[0] * 1440 + hour * 60 + minute
      duration = total_out_minutes - total_in_minutes

      if duration <= grace
        fee = 0
      else
        days = duration / 1440
        remainder = duration % 1440

        if remainder <= 60
          part_fee = first
        else
          part_fee = first + step_fee * ((remainder - 60 + 29) / 30)
        end

        fee = days * cap + [cap, part_fee].min
      end

      hours = duration / 60
      minutes = duration % 60
      fee_str = format("%.2f", fee / 100.0)
      puts "#{plate} #{hours}:#{minutes.to_s.rjust(2, '0')} #{fee_str}"

      exits[plate] ||= []
      exits[plate] << fee

      inside.delete(plate)
    end
  end
end

puts "--- summary"

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

if inside.empty?
  puts "inside: none"
else
  plates = inside.keys.sort
  puts "inside: #{plates.join(', ')}"
end

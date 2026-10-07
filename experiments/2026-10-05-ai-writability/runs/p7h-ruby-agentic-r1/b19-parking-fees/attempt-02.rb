#!/usr/bin/env ruby

def format_money(cents)
  dollars = cents / 100
  remaining_cents = cents % 100
  "#{dollars}.#{remaining_cents.to_s.rjust(2, '0')}"
end

def format_time(minutes)
  hours = minutes / 60
  mins = minutes % 60
  "#{hours}:#{mins.to_s.rjust(2, '0')}"
end

def calculate_fee(duration_minutes, first, step, cap, grace)
  return 0 if duration_minutes <= grace

  # Split into days and remainder
  d = duration_minutes / 1440
  r = duration_minutes % 1440

  # Calculate part(r)
  if r == 0
    part_r = 0
  elsif r <= 60
    part_r = first
  else
    # r > 60: first + step * number of started 30-minute periods after first 60 minutes
    remaining_after_first = r - 60
    periods = (remaining_after_first + 29) / 30  # Round up (number of started periods)
    part_r = first + step * periods
  end

  fee = d * cap + [cap, part_r].min
  fee
end

def parse_time(time_str)
  parts = time_str.split(":")
  if parts.size != 2 || !parts[0].match?(/^\d{2}$/) || !parts[1].match?(/^\d{2}$/)
    return nil
  end
  hours = parts[0].to_i
  mins = parts[1].to_i
  if hours > 23 || mins > 59
    return nil
  end
  hours * 60 + mins  # Return minutes since midnight
end

def is_valid_plate(plate)
  plate.length >= 1 && plate.length <= 8 && plate.match?(/^[A-Z0-9]+$/)
end

def main
  lines = STDIN.readlines.map(&:chomp)

  # Parse rate header
  rate_parts = lines[0].split
  if rate_parts.size != 5 || rate_parts[0] != "RATE"
    # Invalid header, but spec says it's always well formed, so skip
    return
  end

  first = rate_parts[1].to_i
  step = rate_parts[2].to_i
  cap = rate_parts[3].to_i
  grace = rate_parts[4].to_i

  # Track parked cars
  parked_cars = {}  # plate => absolute time in minutes
  current_day = 0
  previous_time_mins = nil

  # Track exits and revenue by plate
  plate_stats = {}  # plate => { exits: count, revenue: cents }

  events = []  # Store output events

  lines[1..].each_with_index do |line, idx|
    line_num = idx + 2

    # Skip blank lines
    next if line.strip.empty?

    parts = line.split

    # Validate format
    if parts.size != 3
      events << "line #{line_num}: invalid"
      next
    end

    time_str, action, plate = parts

    # Parse time
    time_mins = parse_time(time_str)
    if time_mins.nil?
      events << "line #{line_num}: invalid"
      next
    end

    # Validate plate
    if !is_valid_plate(plate)
      events << "line #{line_num}: invalid"
      next
    end

    # Validate action
    if action != "IN" && action != "OUT"
      events << "line #{line_num}: invalid"
      next
    end

    # Check for day change
    if previous_time_mins.nil?
      previous_time_mins = time_mins
    elsif time_mins < previous_time_mins
      current_day += 1
      previous_time_mins = time_mins
    else
      previous_time_mins = time_mins
    end

    absolute_time = current_day * 1440 + time_mins

    if action == "IN"
      if parked_cars.key?(plate)
        events << "line #{line_num}: #{plate} already inside"
      else
        parked_cars[plate] = absolute_time
      end
    else  # OUT
      if !parked_cars.key?(plate)
        events << "line #{line_num}: #{plate} not inside"
      else
        # Calculate fee
        entry_time = parked_cars[plate]
        duration = absolute_time - entry_time
        fee_cents = calculate_fee(duration, first, step, cap, grace)

        events << "#{plate} #{format_time(duration)} #{format_money(fee_cents)}"

        # Update stats
        if !plate_stats.key?(plate)
          plate_stats[plate] = { exits: 0, revenue: 0 }
        end
        plate_stats[plate][:exits] += 1
        plate_stats[plate][:revenue] += fee_cents

        parked_cars.delete(plate)
      end
    end
  end

  # Print events
  events.each { |e| puts e }

  # Print summary
  puts "--- summary"

  if plate_stats.empty?
    total_exits = 0
    total_revenue = 0
  else
    # Sort by revenue descending, then plate ascending
    sorted_plates = plate_stats.keys.sort do |a, b|
      if plate_stats[a][:revenue] != plate_stats[b][:revenue]
        plate_stats[b][:revenue] <=> plate_stats[a][:revenue]
      else
        a <=> b
      end
    end

    total_exits = 0
    total_revenue = 0
    sorted_plates.each do |plate|
      exits = plate_stats[plate][:exits]
      revenue = plate_stats[plate][:revenue]
      puts "#{plate} #{exits} #{format_money(revenue)}"
      total_exits += exits
      total_revenue += revenue
    end
  end

  puts "total #{total_exits} #{format_money(total_revenue)}"

  # Print inside
  inside_plates = parked_cars.keys.sort
  if inside_plates.empty?
    puts "inside: none"
  else
    puts "inside: #{inside_plates.join(", ")}"
  end
end

main

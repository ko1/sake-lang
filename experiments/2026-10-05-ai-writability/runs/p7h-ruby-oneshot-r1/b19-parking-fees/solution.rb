#!/usr/bin/env ruby

# Parse header
rate_line = gets.strip
parts = rate_line.split
unless parts.size == 5 && parts[0] == "RATE" && parts[1..4].all? { |p| /^\d+$/ === p }
  raise "Bad header"
end

first = parts[1].to_i
step = parts[2].to_i
cap = parts[3].to_i
grace = parts[4].to_i

def format_money(cents)
  "%.2f" % (cents / 100.0)
end

def calc_fee(duration_minutes, first, step, cap, grace)
  return 0 if duration_minutes <= grace

  d = duration_minutes / 1440
  r = duration_minutes % 1440

  if r == 0
    part_r = 0
  elsif r <= 60
    part_r = first
  else
    extra = r - 60
    periods = (extra + 29) / 30  # ceiling division
    part_r = first + step * periods
  end

  d * cap + [cap, part_r].min
end

# Track parked cars
inside = {}  # plate => entry_time_minutes
entries = {}  # plate => [time_minutes, day]
exits = []  # [plate, duration, fee]
current_time_minutes = 0
current_day = 0

STDIN.each_line.with_index do |line, idx|
  line_num = idx + 2
  line = line.strip

  next if line.empty?

  parts = line.split(/\s+/)

  if parts.size != 3 || parts[0] !~ /^\d{2}:\d{2}$/ || parts[1] !~ /^(IN|OUT)$/ ||
     parts[2] !~ /^[A-Z0-9]{1,8}$/
    puts "line #{line_num}: invalid"
    next
  end

  time_str = parts[0]
  event = parts[1]
  plate = parts[2]

  hh, mm = time_str.split(':').map(&:to_i)
  time_minutes = hh * 60 + mm

  # Check for new day
  if time_minutes < current_time_minutes
    current_day += 1
  end
  current_time_minutes = time_minutes

  if event == "IN"
    if inside[plate]
      puts "line #{line_num}: #{plate} already inside"
    else
      inside[plate] = time_minutes
      entries[plate] = [time_minutes, current_day]
    end
  else # OUT
    if !inside[plate]
      puts "line #{line_num}: #{plate} not inside"
    else
      entry_time, entry_day = entries[plate]
      # Calculate total minutes considering day change
      duration = (current_day - entry_day) * 1440 + (time_minutes - entry_time)
      fee_cents = calc_fee(duration, first, step, cap, grace)

      hours = duration / 60
      mins = duration % 60
      puts "#{plate} #{hours}:#{mins.to_s.rjust(2, '0')} #{format_money(fee_cents)}"

      exits << [plate, fee_cents]
      inside.delete(plate)
    end
  end
end

# Summary
puts "--- summary"

# Group by plate and sum
plate_totals = {}
exits.each do |plate, fee|
  if !plate_totals[plate]
    plate_totals[plate] = { exits: 0, revenue: 0 }
  end
  plate_totals[plate][:exits] += 1
  plate_totals[plate][:revenue] += fee
end

# Sort by revenue descending, then plate ascending
sorted = plate_totals.sort do |a, b|
  if a[1][:revenue] != b[1][:revenue]
    b[1][:revenue] <=> a[1][:revenue]
  else
    a[0] <=> b[0]
  end
end

total_exits = 0
total_revenue = 0
sorted.each do |plate, data|
  puts "#{plate} #{data[:exits]} #{format_money(data[:revenue])}"
  total_exits += data[:exits]
  total_revenue += data[:revenue]
end

puts "total #{total_exits} #{format_money(total_revenue)}"

# Inside cars
if inside.empty?
  puts "inside: none"
else
  inside_plates = inside.keys.sort
  puts "inside: #{inside_plates.join(', ')}"
end

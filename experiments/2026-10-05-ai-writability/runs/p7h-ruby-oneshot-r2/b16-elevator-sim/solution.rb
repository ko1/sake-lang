#!/usr/bin/env ruby

# Parse header
header = gets.chomp
header_parts = header.split

if header_parts.length != 3 || !header_parts.all? { |p| p.match?(/^\d+$/) }
  puts "invalid header"
  exit
end

n, d, c = header_parts.map(&:to_i)

# Parse requests
requests = []
errors = []
line_num = 2
last_time = -1

while line = gets
  line = line.chomp
  next if line.empty?

  parts = line.split

  valid = parts.length == 3 && parts.all? { |p| p.match?(/^\d+$/) }
  if valid
    t, f, g = parts.map(&:to_i)
    valid = false if f < 1 || f > n || g < 1 || g > n || f == g || t > 1000 || t < last_time
  end

  if !valid
    errors << "line #{line_num}: invalid request"
  else
    t, f, g = parts.map(&:to_i)
    last_time = t
    requests << { time: t, from: f, to: g, num: requests.length + 1 }
  end
  line_num += 1
end

# Print errors
errors.each { |e| puts e }

# Check if there are passengers
if requests.empty?
  puts "no passengers"
  exit
end

# Simulation state
floor = 1
direction = :idle
time = 0
riders = []  # { to: dest, num: passenger_id, picked_up_at: time }
waiting = {} # floor => [requests...]
events = []
delivered = Set.new

# Initialize waiting dict
(1..n).each { |f| waiting[f] = [] }

loop do
  # 1. Add requests that are ready to wait
  requests.each do |req|
    if req[:time] <= time && !delivered.include?(req[:num]) && !waiting[req[:from]].include?(req) && !riders.any? { |r| r[:num] == req[:num] }
      waiting[req[:from]] << req
    end
  end

  # 2. Drop off passengers
  drop_this_step = riders.select { |r| r[:to] == floor }
  drop_this_step.sort_by { |r| r[:num] }.each do |passenger|
    riders.delete(passenger)
    delivered.add(passenger[:num])
    events << "t=#{time} floor #{floor} drop P#{passenger[:num]}"
  end

  # 3. Determine next direction
  # Targets are: rider destinations + waiting passenger floors
  targets = []
  riders.each { |r| targets << r[:to] }
  waiting.each { |f, reqs| targets << f if reqs.any? }

  if direction == :up
    if targets.any? { |t| t > floor }
      # Stay up
    elsif targets.any? { |t| t < floor }
      direction = :down
    else
      direction = :idle
    end
  elsif direction == :down
    if targets.any? { |t| t < floor }
      # Stay down
    elsif targets.any? { |t| t > floor }
      direction = :up
    else
      direction = :idle
    end
  else # :idle
    if targets.any?
      # Find nearest target
      nearest_targets = targets.sort_by { |t| [( t - floor).abs, t] }
      nearest = nearest_targets[0]

      if nearest < floor
        direction = :down
      elsif nearest > floor
        direction = :up
      else # nearest == floor
        # If we're idle at floor and there are targets at this floor, choose direction of lowest waiting passenger
        if waiting[floor].any?
          lowest = waiting[floor].min_by { |w| w[:num] }
          direction = lowest[:to] > floor ? :up : :down
        else
          direction = :idle
        end
      end
    end
  end

  # 4. Board passengers
  pick_this_step = []
  if waiting[floor].any?
    waiting[floor].each do |passenger|
      break if riders.length + pick_this_step.length >= c

      passenger_direction = passenger[:to] > floor ? :up : :down
      if passenger_direction == direction || (direction == :idle && passenger[:to] == floor)
        pick_this_step << passenger
      end
    end

    pick_this_step.sort_by { |w| w[:num] }.each do |passenger|
      riders << { to: passenger[:to], num: passenger[:num], picked_up_at: time }
      waiting[floor].delete(passenger)
      events << "t=#{time} floor #{floor} pick P#{passenger[:num]}"
    end
  end

  # Check if we're done
  if riders.empty? && delivered.length == requests.length
    break
  end

  # 5. Move or wait at door
  if drop_this_step.any? || pick_this_step.any?
    time += d
  else
    case direction
    when :up
      floor += 1
    when :down
      floor -= 1
    end
    time += 1
  end
end

# Output events
events.each { |e| puts e }

# Statistics
wait_times = []
ride_times = []
last_drop_time = 0

requests.each do |req|
  pick_event = events.find { |e| e.include?("pick P#{req[:num]}") }
  drop_event = events.find { |e| e.include?("drop P#{req[:num]}") }

  if pick_event && drop_event
    pick_time = pick_event.match(/t=(\d+)/)[1].to_i
    drop_time = drop_event.match(/t=(\d+)/)[1].to_i
    last_drop_time = drop_time

    wait = pick_time - req[:time]
    ride = drop_time - pick_time

    wait_times << wait
    ride_times << ride

    puts "P#{req[:num]} wait #{wait} ride #{ride}"
  end
end

avg_wait = wait_times.sum.to_f / wait_times.length
avg_ride = ride_times.sum.to_f / ride_times.length

printf "average wait %.2f ride %.2f\n", avg_wait, avg_ride
puts "done at t=#{last_drop_time}"

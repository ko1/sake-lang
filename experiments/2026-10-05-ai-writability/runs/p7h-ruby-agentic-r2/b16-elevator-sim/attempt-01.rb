#!/usr/bin/env ruby

lines = STDIN.readlines
header_parts = lines[0].strip.split(/\s+/)

# Validate header
if header_parts.size != 3 || header_parts.any? { |p| !/^\d+$/.match?(p) }
  puts "invalid header"
  exit
end

n, d, c = header_parts.map(&:to_i)

# Parse requests
requests = []
invalid_lines = []
last_time = -1

lines[1..].each_with_index do |line, idx|
  line = line.strip
  next if line.empty?

  line_num = idx + 2  # 1-based line number
  parts = line.split(/\s+/)

  if parts.size != 3 || parts.any? { |p| !/^\d+$/.match?(p) }
    invalid_lines << "line #{line_num}: invalid request"
    next
  end

  t, f, g = parts.map(&:to_i)

  if f < 1 || f > n || g < 1 || g > n || f == g || t > 1000 || t < last_time
    invalid_lines << "line #{line_num}: invalid request"
    next
  end

  last_time = t
  requests << {request_time: t, from: f, to: g, id: requests.size + 1}
end

invalid_lines.each { |msg| puts msg }

if requests.empty?
  puts "no passengers"
  exit
end

# Simulation
current_floor = 1
current_time = 0
direction = :idle  # :up, :down, :idle
riders = []        # passengers currently in elevator
waiting = {}       # floor => [passenger_ids]
passenger_state = {}  # id => {request_time, from, to, picked_up_time, dropped_off_time}

requests.each do |req|
  passenger_state[req[:id]] = {
    request_time: req[:request_time],
    from: req[:from],
    to: req[:to],
    picked_up_time: nil,
    dropped_off_time: nil
  }
end

events = []

loop do
  # Check if all passengers dropped off
  break if passenger_state.all? { |_, state| state[:dropped_off_time] }

  # 1. Requests with T <= t start waiting
  requests.each do |req|
    if req[:request_time] <= current_time && !waiting[req[:from]]
      waiting[req[:from]] = []
    end
    if req[:request_time] <= current_time
      if !waiting[req[:from]].include?(req[:id])
        waiting[req[:from]] << req[:id]
      end
    end
  end

  # 2. Drop off passengers
  to_drop = riders.select { |id| passenger_state[id][:to] == current_floor }
  to_drop.each do |id|
    passenger_state[id][:dropped_off_time] = current_time
    events << "t=#{current_time} floor #{current_floor} drop P#{id}"
    riders.delete(id)
  end

  # 3. Determine targets and update direction
  targets = riders.map { |id| passenger_state[id][:to] }.uniq +
            (waiting[current_floor] || []).map { |id| passenger_state[id][:to] }.uniq

  targets = targets.reject { |t| t == current_floor }.uniq

  if direction == :up
    if targets.any? { |f| f > current_floor }
      direction = :up
    elsif targets.any? { |f| f < current_floor }
      direction = :down
    else
      direction = :idle
    end
  elsif direction == :down
    if targets.any? { |f| f < current_floor }
      direction = :down
    elsif targets.any? { |f| f > current_floor }
      direction = :up
    else
      direction = :idle
    end
  else  # idle
    if targets.empty?
      direction = :idle
    else
      nearest = targets.min_by { |f| (f - current_floor).abs }
      if targets.select { |f| (f - current_floor).abs == (nearest - current_floor).abs }.size > 1
        nearest = targets.select { |f| (f - current_floor).abs == (nearest - current_floor).abs }.min
      end
      direction = nearest > current_floor ? :up : :down

      if nearest == current_floor
        waiting_at_floor = waiting[current_floor] || []
        if waiting_at_floor.any?
          min_passenger = waiting_at_floor.min
          min_dir = if passenger_state[min_passenger][:to] > current_floor
            :up
          else
            :down
          end
          direction = min_dir
        end
      end
    end
  end

  # 4. Pick up passengers
  to_pick = []
  if waiting[current_floor]
    waiting[current_floor].each do |id|
      break if riders.size >= c
      passenger_floor = passenger_state[id][:from]
      passenger_dest = passenger_state[id][:to]
      passenger_dir = passenger_dest > passenger_floor ? :up : :down

      if passenger_dir == direction
        to_pick << id
        riders << id
        passenger_state[id][:picked_up_time] = current_time
        events << "t=#{current_time} floor #{current_floor} pick P#{id}"
        waiting[current_floor].delete(id)
      end
    end
  end

  # 5. Move or wait
  if to_drop.any? || to_pick.any?
    current_time += d
  else
    if direction == :up
      current_floor += 1
    elsif direction == :down
      current_floor -= 1
    end
    current_time += 1
  end
end

events.each { |e| puts e }

wait_times = []
ride_times = []
requests.each do |req|
  id = req[:id]
  state = passenger_state[id]
  wait = state[:picked_up_time] - state[:request_time]
  ride = state[:dropped_off_time] - state[:picked_up_time]
  wait_times << wait
  ride_times << ride
  puts "P#{id} wait #{wait} ride #{ride}"
end

avg_wait = wait_times.sum.to_f / wait_times.size
avg_ride = ride_times.sum.to_f / ride_times.size
puts "average wait %.2f ride %.2f" % [avg_wait, avg_ride]

last_drop_time = passenger_state.values.map { |s| s[:dropped_off_time] }.max
puts "done at t=#{last_drop_time}"

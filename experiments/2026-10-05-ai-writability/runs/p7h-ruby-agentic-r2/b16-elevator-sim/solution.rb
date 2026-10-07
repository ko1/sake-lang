#!/usr/bin/env ruby

lines = STDIN.readlines
header_parts = lines[0].strip.split(/\s+/)

if header_parts.size != 3 || header_parts.any? { |p| !/^\d+$/.match?(p) }
  puts "invalid header"
  exit
end

n, d, c = header_parts.map(&:to_i)

requests = []
invalid_lines = []
last_time = -1

lines[1..].each_with_index do |line, idx|
  line = line.strip
  next if line.empty?

  line_num = idx + 2
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

current_floor = 1
current_time = 0
direction = :idle
riders = []
events = []

passenger_state = {}
requests.each do |req|
  passenger_state[req[:id]] = {
    request_time: req[:request_time],
    from: req[:from],
    to: req[:to],
    picked_up_time: nil,
    dropped_off_time: nil,
    state: :pending
  }
end

done_count = 0
iteration_count = 0
loop do
  iteration_count += 1
  break if done_count == requests.size
  if iteration_count > 100000
    puts "ERROR: Too many iterations"
    break
  end

  # 1. Activate waiting passengers
  requests.each do |req|
    if passenger_state[req[:id]][:state] == :pending &&
       passenger_state[req[:id]][:request_time] <= current_time
      passenger_state[req[:id]][:state] = :waiting
    end
  end

  # 2. Drop off passengers
  to_drop_count = 0
  riders.each do |id|
    if passenger_state[id][:to] == current_floor
      passenger_state[id][:dropped_off_time] = current_time
      passenger_state[id][:state] = :done
      events << "t=#{current_time} floor #{current_floor} drop P#{id}"
      to_drop_count += 1
      done_count += 1
    end
  end
  riders.reject! { |id| passenger_state[id][:state] == :done }

  break if done_count == requests.size

  # 3. Determine direction
  targets = Set.new
  riders.each { |id| targets << passenger_state[id][:to] }
  requests.each do |req|
    if passenger_state[req[:id]][:state] == :waiting
      targets << passenger_state[req[:id]][:from]
    end
  end

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
      distances = targets.map { |f| (f - current_floor).abs }
      min_dist = distances.min
      nearest_candidates = targets.select { |f| (f - current_floor).abs == min_dist }
      nearest = nearest_candidates.min

      if nearest == current_floor
        # Take direction of lowest-numbered waiting passenger
        waiting_at_floor = requests.select do |req|
          passenger_state[req[:id]][:state] == :waiting &&
          passenger_state[req[:id]][:from] == current_floor
        end
        if waiting_at_floor.any?
          min_req = waiting_at_floor.min_by { |req| req[:id] }
          to_floor = min_req[:to]
          direction = to_floor > current_floor ? :up : :down
        else
          direction = :idle
        end
      else
        direction = nearest > current_floor ? :up : :down
      end
    end
  end

  # 4. Pick up passengers
  to_pick_count = 0
  waiting_here = requests.select do |req|
    passenger_state[req[:id]][:state] == :waiting &&
    passenger_state[req[:id]][:from] == current_floor
  end

  waiting_here.sort_by { |req| req[:id] }.each do |req|
    break if riders.size >= c
    id = req[:id]
    to_floor = passenger_state[id][:to]
    passenger_dir = to_floor > current_floor ? :up : :down

    if passenger_dir == direction
      riders << id
      passenger_state[id][:picked_up_time] = current_time
      passenger_state[id][:state] = :riding
      events << "t=#{current_time} floor #{current_floor} pick P#{id}"
      to_pick_count += 1
    end
  end

  # 5. Move or wait
  if to_drop_count > 0 || to_pick_count > 0
    current_time += d
  else
    case direction
    when :up
      current_floor += 1
    when :down
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

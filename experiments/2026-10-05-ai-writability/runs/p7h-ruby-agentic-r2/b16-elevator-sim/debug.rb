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
iterations = 0

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

loop do
  iterations += 1
  if iterations > 1000
    puts "DEBUG: Too many iterations, stopping"
    break
  end

  break if done_count == requests.size

  puts "DEBUG: t=#{current_time}, floor=#{current_floor}, dir=#{direction}, riders=#{riders.inspect}, done=#{done_count}/#{requests.size}"

  # 1. Activate waiting passengers
  requests.each do |req|
    if passenger_state[req[:id]][:state] == :pending &&
       passenger_state[req[:id]][:request_time] <= current_time
      passenger_state[req[:id]][:state] = :waiting
    end
  end

  # 2. Drop off passengers
  to_drop = riders.select { |id| passenger_state[id][:to] == current_floor }
  to_drop.each do |id|
    passenger_state[id][:dropped_off_time] = current_time
    passenger_state[id][:state] = :done
    events << "t=#{current_time} floor #{current_floor} drop P#{id}"
    riders.delete(id)
    done_count += 1
  end

  break if done_count == requests.size

  # 3. Calculate targets and update direction
  targets = Set.new
  riders.each { |id| targets << passenger_state[id][:to] }
  requests.each do |req|
    if passenger_state[req[:id]][:state] == :waiting
      targets << passenger_state[req[:id]][:from]
    end
  end

  puts "DEBUG: targets before delete = #{targets.inspect}"
  targets.delete(current_floor)
  puts "DEBUG: targets after delete = #{targets.inspect}"

  if targets.empty?
    direction = :idle
  else
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
        nearest = targets.select { |f| (f - current_floor).abs == min_dist }.min

        if nearest > current_floor
          direction = :up
        else
          direction = :down
        end
      end
    end
  end

  puts "DEBUG: direction = #{direction}"

  # 4. Pick up passengers
  to_pick = []
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
      to_pick << id
      riders << id
      passenger_state[id][:picked_up_time] = current_time
      passenger_state[id][:state] = :riding
      events << "t=#{current_time} floor #{current_floor} pick P#{id}"
    end
  end

  # 5. Move or wait
  if to_drop.any? || to_pick.any?
    puts "DEBUG: Door activity, waiting #{d} time units"
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

puts "---"
events.each { |e| puts e }

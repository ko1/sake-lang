#!/usr/bin/env ruby

# Parse header
header_line = gets.strip
parts = header_line.split
unless parts.size == 3 && parts.all? { |p| /^\d+$/ === p }
  puts "invalid header"
  exit
end

N, D, C = parts.map(&:to_i)

# Parse requests
requests = []
invalid_lines = []
line_num = 2
last_t = -1

loop do
  line = gets
  break unless line

  line = line.strip
  next if line.empty?

  parts = line.split

  if parts.size != 3 || !parts.all? { |p| /^\d+$/ === p }
    invalid_lines << "line #{line_num}: invalid request"
    line_num += 1
    next
  end

  T, F, G = parts.map(&:to_i)

  valid = true
  if F < 1 || F > N || G < 1 || G > N
    valid = false
  elsif F == G
    valid = false
  elsif T > 1000
    valid = false
  elsif T < last_t
    valid = false
  end

  if valid
    requests << { t: T, f: F, g: G, id: requests.size + 1 }
    last_t = T
  else
    invalid_lines << "line #{line_num}: invalid request"
  end

  line_num += 1
end

# Print invalid lines
invalid_lines.each { |msg| puts msg }

if requests.empty?
  puts "no passengers"
  exit
end

# Simulate
elevator_floor = 1
elevator_time = 0
elevator_direction = :idle  # :up, :down, :idle
waiting = {}  # { floor => [request_ids] }
boarded = {}  # { passenger_id => true }
dropped = {}  # { passenger_id => true }
pickup_times = {}
dropoff_times = {}

# Pick up map: passenger_id -> waiting floor
pickup_floor = {}
requests.each { |r| pickup_floor[r[:id]] = r[:f] }

until dropped.size == requests.size
  # 1. Passengers with T <= t start waiting
  requests.each do |req|
    if req[:t] <= elevator_time && !waiting[req[:f]]
      waiting[req[:f]] = []
    end
    waiting[req[:f]] ||= []
    waiting[req[:f]] << req[:id] if req[:t] <= elevator_time && !waiting[req[:f]].include?(req[:id]) && !boarded[req[:id]]
  end

  # 2. Drop-offs
  dropped_this_step = []
  boarded.each do |pid, _|
    req = requests[pid - 1]
    if req[:g] == elevator_floor
      dropped[pid] = true
      boarded.delete(pid)
      dropped_this_step << pid
      dropoff_times[pid] = elevator_time
    end
  end

  dropped_this_step.sort.each do |pid|
    puts "t=#{elevator_time} floor #{elevator_floor} drop P#{pid}"
  end

  # 3. Determine direction
  targets = []
  boarded.each do |pid, _|
    req = requests[pid - 1]
    targets << req[:g]
  end
  waiting.each do |floor, ids|
    ids.each { |id| targets << floor unless boarded[id] }
  end
  targets.uniq!

  if elevator_direction == :up
    if targets.any? { |t| t > elevator_floor }
      # stay :up
    elsif targets.any? { |t| t < elevator_floor }
      elevator_direction = :down
    else
      elevator_direction = :idle
    end
  elsif elevator_direction == :down
    if targets.any? { |t| t < elevator_floor }
      # stay :down
    elsif targets.any? { |t| t > elevator_floor }
      elevator_direction = :up
    else
      elevator_direction = :idle
    end
  elsif elevator_direction == :idle
    if targets.empty?
      # stay idle
    else
      nearest = targets.min_by { |t| (t - elevator_floor).abs }
      if targets.select { |t| (t - elevator_floor).abs == (nearest - elevator_floor).abs }.size > 1
        nearest = targets.select { |t| (t - elevator_floor).abs == (nearest - elevator_floor).abs }.min
      end
      if nearest == elevator_floor
        if waiting[elevator_floor]
          waiting_dirs = waiting[elevator_floor].map { |id| requests[id - 1][:g] <=> elevator_floor }
          elevator_direction = waiting_dirs.include?(-1) ? :down : :up
        end
      elsif nearest > elevator_floor
        elevator_direction = :up
      else
        elevator_direction = :down
      end
    end
  end

  # 4. Boarding
  boarded_this_step = []
  if waiting[elevator_floor]
    waiting[elevator_floor].each do |pid|
      if boarded.size < C
        req = requests[pid - 1]
        dir_to_dest = req[:g] <=> elevator_floor
        elev_dir_val = elevator_direction == :up ? 1 : elevator_direction == :down ? -1 : 0
        if (elevator_direction == :idle) || (dir_to_dest == elev_dir_val)
          boarded[pid] = true
          boarded_this_step << pid
          pickup_times[pid] = elevator_time
        end
      end
    end
    boarded_this_step.sort.each do |pid|
      waiting[elevator_floor].delete(pid)
      puts "t=#{elevator_time} floor #{elevator_floor} pick P#{pid}"
    end
  end

  # 5. Next step
  if dropped_this_step.any? || boarded_this_step.any?
    elevator_time += D
  else
    case elevator_direction
    when :up
      elevator_floor += 1
    when :down
      elevator_floor -= 1
    end
    elevator_time += 1
  end
end

# Print statistics
total_wait = 0
total_ride = 0
requests.each do |req|
  wait = pickup_times[req[:id]] - req[:t]
  ride = dropoff_times[req[:id]] - pickup_times[req[:id]]
  puts "P#{req[:id]} wait #{wait} ride #{ride}"
  total_wait += wait
  total_ride += ride
end

avg_wait = total_wait.to_f / requests.size
avg_ride = total_ride.to_f / requests.size
puts "average wait %.2f ride %.2f" % [avg_wait, avg_ride]

puts "done at t=#{dropoff_times.values.max}"

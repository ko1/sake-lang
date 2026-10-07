#!/usr/bin/env ruby

def main
  lines = STDIN.readlines.map(&:chomp)

  # Parse header
  header_parts = lines[0].split
  if header_parts.size != 3 || !header_parts.all? { |p| p.match?(/^\d+$/) }
    puts "invalid header"
    return
  end

  n, d, c = header_parts.map(&:to_i)

  # Parse and validate requests
  valid_requests = []
  invalid_lines = []
  last_t = -1

  lines[1..].each_with_index do |line, idx|
    line_num = idx + 2
    next if line.empty?

    parts = line.split
    if parts.size != 3 || !parts.all? { |p| p.match?(/^\d+$/) }
      invalid_lines << line_num
      next
    end

    t, f, g = parts.map(&:to_i)

    invalid = false
    invalid = true if f < 1 || f > n
    invalid = true if g < 1 || g > n
    invalid = true if f == g
    invalid = true if t > 1000
    invalid = true if t < last_t

    if invalid
      invalid_lines << line_num
    else
      valid_requests << { t: t, f: f, g: g, idx: valid_requests.size + 1 }
      last_t = t
    end
  end

  # Print invalid lines
  invalid_lines.each { |ln| puts "line #{ln}: invalid request" }

  # Check if there are any valid requests
  if valid_requests.empty?
    puts "no passengers"
    return
  end

  # Simulate elevator
  elevator_floor = 1
  elevator_dir = :idle
  time = 0

  # Track passenger state: :waiting, :riding, :done
  # passengers[i] = { t: request_time, f: start_floor, g: dest_floor, state: :waiting }
  passengers = valid_requests.map { |r| { t: r[:t], f: r[:f], g: r[:g], state: :waiting, idx: r[:idx] } }

  riders = []  # passenger indices currently in elevator

  events = []  # Array of [time, floor, event_type, passenger_indices]

  loop do
    # Check if all passengers are done
    break if passengers.all? { |p| p[:state] == :done }

    # 1. Requests with T <= t start waiting
    passengers.each { |p| p[:state] = :waiting if p[:state] == :waiting && p[:t] <= time }

    # Track changes at this time step
    dropped_off = []
    picked_up = []

    # 2. Riders whose destination is floor get off
    riders.each do |idx|
      if passengers[idx][:g] == elevator_floor
        dropped_off << idx
        passengers[idx][:state] = :done
      end
    end

    riders.reject! { |idx| dropped_off.include?(idx) }

    # 3. Determine direction
    waiting_at_floor = passengers.each_with_index.select { |p, i| p[:state] == :waiting && p[:f] == elevator_floor }.map { |_, i| i }

    targets = []
    riders.each { |idx| targets << passengers[idx][:g] }
    waiting_at_floor.each { |idx| targets << elevator_floor }
    waiting_others = passengers.each_with_index.select { |p, i| p[:state] == :waiting && p[:f] != elevator_floor }.map { |_, i| i }
    waiting_others.each { |idx| targets << passengers[idx][:f] }

    targets.uniq!

    new_dir = elevator_dir
    if !targets.empty?
      above = targets.select { |t| t > elevator_floor }
      below = targets.select { |t| t < elevator_floor }

      if elevator_dir == :up
        new_dir = :up if !above.empty?
        new_dir = :down if above.empty? && !below.empty?
        new_dir = :idle if above.empty? && below.empty?
      elsif elevator_dir == :down
        new_dir = :down if !below.empty?
        new_dir = :up if below.empty? && !above.empty?
        new_dir = :idle if below.empty? && above.empty?
      else  # idle
        if !above.empty?
          new_dir = :up
        elsif !below.empty?
          new_dir = :down
        elsif !targets.select { |t| t == elevator_floor }.empty?
          # Determine direction from lowest-numbered waiting passenger at this floor
          waiting_here = passengers.each_with_index.select { |p, i| p[:state] == :waiting && p[:f] == elevator_floor }.map { |_, i| i }.sort
          if !waiting_here.empty?
            new_dir = passengers[waiting_here[0]][:g] > elevator_floor ? :up : :down
          end
        end
      end
    end

    elevator_dir = new_dir

    # 4. Waiting passengers at floor whose direction equals elevator's get on
    waiting_at_floor = passengers.each_with_index.select { |p, i| p[:state] == :waiting && p[:f] == elevator_floor }.map { |_, i| i }.sort

    waiting_at_floor.each do |idx|
      break if riders.size >= c
      pass_dir = passengers[idx][:g] > elevator_floor ? :up : :down
      if pass_dir == elevator_dir || elevator_dir == :idle
        picked_up << idx
        riders << idx
        passengers[idx][:state] = :riding
      end
    end

    # Record events
    dropped_off.sort.each do |idx|
      events << [time, elevator_floor, "drop", idx]
    end

    picked_up.sort.each do |idx|
      events << [time, elevator_floor, "pick", idx]
    end

    # 5. Determine time increase
    if !dropped_off.empty? || !picked_up.empty?
      time += d
    else
      # Move elevator
      case elevator_dir
      when :up
        elevator_floor += 1
      when :down
        elevator_floor -= 1
      end
      time += 1
    end
  end

  # Print events
  events.each do |e|
    time, floor, type, idx = e
    puts "t=#{time} floor #{floor} #{type} P#{passengers[idx][:idx]}"
  end

  # Calculate stats
  wait_times = []
  ride_times = []

  passengers.each_with_index do |p, idx|
    # Find pick-up and drop-off times
    pickup_event = events.find { |e| e[3] == idx && e[2] == "pick" }
    dropoff_event = events.find { |e| e[3] == idx && e[2] == "drop" }

    if pickup_event && dropoff_event
      wait = pickup_event[0] - p[:t]
      ride = dropoff_event[0] - pickup_event[0]
      wait_times << wait
      ride_times << ride
    end
  end

  # Print per-passenger stats
  passengers.each do |p|
    idx = p[:idx] - 1
    pickup_event = events.find { |e| e[3] == idx && e[2] == "pick" }
    dropoff_event = events.find { |e| e[3] == idx && e[2] == "drop" }

    if pickup_event && dropoff_event
      wait = pickup_event[0] - p[:t]
      ride = dropoff_event[0] - pickup_event[0]
      puts "P#{p[:idx]} wait #{wait} ride #{ride}"
    end
  end

  # Print averages
  avg_wait = wait_times.sum.to_f / wait_times.size
  avg_ride = ride_times.sum.to_f / ride_times.size
  puts "average wait %.2f ride %.2f" % [avg_wait, avg_ride]

  # Print done time
  last_dropoff = events.select { |e| e[2] == "drop" }.max_by { |e| e[0] }
  if last_dropoff
    puts "done at t=#{last_dropoff[0]}"
  end
end

main

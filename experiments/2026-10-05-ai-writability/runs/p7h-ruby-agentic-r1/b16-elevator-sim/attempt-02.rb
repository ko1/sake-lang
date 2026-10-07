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

  # passengers[i] = { t: arrival_time, f: start_floor, g: dest_floor, waiting: false, riding: false, done: false, idx: 1-based passenger number }
  passengers = valid_requests.map { |r| { t: r[:t], f: r[:f], g: r[:g], waiting: false, riding: false, done: false, idx: r[:idx] } }

  riders = []  # Array of passenger indices currently in elevator

  events = []  # Array of [time, floor, type (pick/drop), passenger_index]

  loop do
    # Check if all passengers are done
    break if passengers.all? { |p| p[:done] }

    # 1. Requests with T <= t start waiting
    passengers.each do |p|
      if !p[:waiting] && !p[:riding] && !p[:done] && p[:t] <= time
        p[:waiting] = true
      end
    end

    events_this_step = []

    # 2. Riders whose destination is floor get off (drop-offs)
    new_riders = []
    riders.each do |pidx|
      if passengers[pidx][:g] == elevator_floor
        events_this_step << [:drop, pidx]
        passengers[pidx][:done] = true
        passengers[pidx][:riding] = false
      else
        new_riders << pidx
      end
    end
    riders = new_riders

    # 3. Determine new direction
    # Targets = riders' destinations + waiting passengers' floors
    targets = []
    riders.each { |pidx| targets << passengers[pidx][:g] }
    (0...passengers.size).each do |pidx|
      if passengers[pidx][:waiting]
        targets << passengers[pidx][:f]
      end
    end
    targets.uniq!

    if !targets.empty?
      above = targets.select { |t| t > elevator_floor }
      below = targets.select { |t| t < elevator_floor }
      at_floor = targets.select { |t| t == elevator_floor }

      case elevator_dir
      when :up
        if !above.empty?
          elevator_dir = :up
        elsif !below.empty?
          elevator_dir = :down
        elsif !at_floor.empty?
          # Direction determined by direction of the lowest-numbered passenger waiting at floor
          waiting_at_floor = (0...passengers.size).select { |pidx| passengers[pidx][:waiting] && passengers[pidx][:f] == elevator_floor }.sort
          if !waiting_at_floor.empty?
            dest = passengers[waiting_at_floor[0]][:g]
            elevator_dir = dest > elevator_floor ? :up : :down
          else
            elevator_dir = :idle
          end
        else
          elevator_dir = :idle
        end
      when :down
        if !below.empty?
          elevator_dir = :down
        elsif !above.empty?
          elevator_dir = :up
        elsif !at_floor.empty?
          # Direction determined by direction of the lowest-numbered passenger waiting at floor
          waiting_at_floor = (0...passengers.size).select { |pidx| passengers[pidx][:waiting] && passengers[pidx][:f] == elevator_floor }.sort
          if !waiting_at_floor.empty?
            dest = passengers[waiting_at_floor[0]][:g]
            elevator_dir = dest > elevator_floor ? :up : :down
          else
            elevator_dir = :idle
          end
        else
          elevator_dir = :idle
        end
      else  # idle
        if !above.empty?
          elevator_dir = :up
        elsif !below.empty?
          elevator_dir = :down
        elsif !at_floor.empty?
          # Direction determined by direction of the lowest-numbered passenger waiting at floor
          waiting_at_floor = (0...passengers.size).select { |pidx| passengers[pidx][:waiting] && passengers[pidx][:f] == elevator_floor }.sort
          if !waiting_at_floor.empty?
            dest = passengers[waiting_at_floor[0]][:g]
            elevator_dir = dest > elevator_floor ? :up : :down
          else
            elevator_dir = :idle
          end
        end
      end
    end

    # 4. Waiting passengers at floor whose direction equals elevator's get on
    waiting_at_floor = (0...passengers.size).select { |pidx| passengers[pidx][:waiting] && passengers[pidx][:f] == elevator_floor }.sort

    waiting_at_floor.each do |pidx|
      break if riders.size >= c
      pass_dir = passengers[pidx][:g] > elevator_floor ? :up : :down
      if pass_dir == elevator_dir
        events_this_step << [:pick, pidx]
        riders << pidx
        passengers[pidx][:waiting] = false
        passengers[pidx][:riding] = true
      end
    end

    # Record events
    events_this_step.each do |type, pidx|
      events << [time, elevator_floor, type, pidx]
    end

    # 5. Determine time increase
    if !events_this_step.empty?
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
    time, floor, type, pidx = e
    type_str = type == :pick ? "pick" : "drop"
    puts "t=#{time} floor #{floor} #{type_str} P#{passengers[pidx][:idx]}"
  end

  # Calculate and print per-passenger stats and collect wait/ride times
  wait_times = []
  ride_times = []

  valid_requests.each_with_index do |_, orig_idx|
    pickup_event = events.find { |e| e[3] == orig_idx && e[2] == :pick }
    dropoff_event = events.find { |e| e[3] == orig_idx && e[2] == :drop }

    if pickup_event && dropoff_event
      p = passengers[orig_idx]
      wait = pickup_event[0] - p[:t]
      ride = dropoff_event[0] - pickup_event[0]
      wait_times << wait
      ride_times << ride
      puts "P#{p[:idx]} wait #{wait} ride #{ride}"
    end
  end

  # Print averages
  avg_wait = wait_times.sum.to_f / wait_times.size
  avg_ride = ride_times.sum.to_f / ride_times.size
  puts "average wait %.2f ride %.2f" % [avg_wait, avg_ride]

  # Print done time
  last_dropoff = events.select { |e| e[2] == :drop }.max_by { |e| e[0] }
  if last_dropoff
    puts "done at t=#{last_dropoff[0]}"
  end
end

main

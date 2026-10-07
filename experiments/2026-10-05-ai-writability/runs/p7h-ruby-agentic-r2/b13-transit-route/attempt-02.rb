#!/usr/bin/env ruby

# Read input
lines = STDIN.readlines.map(&:strip)

# Parse transfer penalty
transfer_penalty = lines[0].to_i

# Parse segments
segments = []
stations = Set.new
line_number = 2
queries_line_idx = nil

while line_number - 1 < lines.length
  line = lines[line_number - 1]

  if line == "QUERIES"
    queries_line_idx = line_number
    break
  end

  if line.empty?
    line_number += 1
    next
  end

  fields = line.split

  if fields.length != 4
    puts "invalid segment at line #{line_number}"
    line_number += 1
    next
  end

  line_name = fields[0]
  station_a = fields[1]
  station_b = fields[2]
  minutes_str = fields[3]

  # Validate
  if station_a == station_b
    puts "invalid segment at line #{line_number}"
    line_number += 1
    next
  end

  # Check if minutes is valid (no leading zeros, integer 1-999)
  is_valid = false
  if minutes_str.match?(/^\d+$/)
    if minutes_str.length == 1 || (minutes_str.length > 1 && !minutes_str.start_with?("0"))
      minutes = minutes_str.to_i
      if minutes >= 1 && minutes <= 999
        is_valid = true
      end
    end
  end

  unless is_valid
    puts "invalid segment at line #{line_number}"
    line_number += 1
    next
  end

  segments << { line: line_name, a: station_a, b: station_b, minutes: minutes }
  stations.add(station_a)
  stations.add(station_b)

  line_number += 1
end

# Parse queries
queries = []
if queries_line_idx
  query_line_idx = queries_line_idx + 1
  while query_line_idx - 1 < lines.length
    line = lines[query_line_idx - 1]

    if line.empty?
      query_line_idx += 1
      next
    end

    fields = line.split

    if fields.length != 2
      puts "invalid query at line #{query_line_idx}"
      query_line_idx += 1
      next
    end

    queries << { from: fields[0], to: fields[1], line_idx: query_line_idx }
    query_line_idx += 1
  end
end

# Process queries
queries.each do |query|
  from = query[:from]
  to = query[:to]

  # Check if stations are known
  if !stations.include?(from)
    puts "#{from} -> #{to}: unknown station #{from}"
    next
  end

  if !stations.include?(to)
    puts "#{from} -> #{to}: unknown station #{to}"
    next
  end

  # If from == to
  if from == to
    puts "#{from} -> #{to}: 0 min, 0 transfers"
    next
  end

  # Find shortest path using Dijkstra with custom comparison
  # Build adjacency list
  graph = {}
  stations.each { |s| graph[s] = [] }
  segments.each do |seg|
    graph[seg[:a]] << { to: seg[:b], line: seg[:line], minutes: seg[:minutes] }
    graph[seg[:b]] << { to: seg[:a], line: seg[:line], minutes: seg[:minutes] }
  end

  # Dijkstra with custom comparison
  visited = Set.new
  pq = [[0, 0, [from], [], from]]  # [cost, transfers, path_stations, path_lines, current_station]
  best_path = nil

  while pq.any?
    # Get the state with the best priority (cost, transfers, stations, lines)
    best_idx = 0
    best_priority = pq[0]

    pq.each_with_index do |state, idx|
      priority = state[0..3]
      if priority <=> best_priority[0..3] < 0
        best_idx = idx
        best_priority = state
      end
    end

    state = pq.delete_at(best_idx)
    cost, transfers, path_stations, path_lines, current = state

    if current == to
      best_path = { cost: cost, transfers: transfers, stations: path_stations, lines: path_lines }
      break
    end

    next if visited.include?(current)
    visited.add(current)

    # Explore neighbors
    graph[current].each do |edge|
      next_station = edge[:to]
      line_name = edge[:line]
      minutes = edge[:minutes]

      next if visited.include?(next_station)

      # Calculate cost and transfers for this edge
      if path_lines.empty?
        new_cost = cost + minutes
        new_transfers = 0
        new_lines = [line_name]
      elsif path_lines[-1] == line_name
        new_cost = cost + minutes
        new_transfers = transfers
        new_lines = path_lines + [line_name]
      else
        new_cost = cost + minutes + transfer_penalty
        new_transfers = transfers + 1
        new_lines = path_lines + [line_name]
      end

      new_stations = path_stations + [next_station]
      pq << [new_cost, new_transfers, new_stations, new_lines, next_station]
    end
  end

  # Output
  if best_path
    transfer_word = best_path[:transfers] == 1 ? "transfer" : "transfers"
    puts "#{from} -> #{to}: #{best_path[:cost]} min, #{best_path[:transfers]} #{transfer_word}"

    if best_path[:transfers] > 0
      # Group legs by consecutive same line
      legs = []
      current_line = best_path[:lines][0]
      current_leg_stations = [best_path[:stations][0], best_path[:stations][1]]

      (1...best_path[:lines].length).each do |i|
        if best_path[:lines][i] == current_line
          current_leg_stations << best_path[:stations][i + 1]
        else
          legs << "#{current_line}: #{current_leg_stations.join(" > ")}"
          current_line = best_path[:lines][i]
          current_leg_stations = [best_path[:stations][i], best_path[:stations][i + 1]]
        end
      end
      legs << "#{current_line}: #{current_leg_stations.join(" > ")}"

      puts "  #{legs.join("; ")}"
    end
  else
    puts "#{from} -> #{to}: no route"
  end
end

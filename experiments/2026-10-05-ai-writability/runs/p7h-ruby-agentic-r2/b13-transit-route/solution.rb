#!/usr/bin/env ruby

# Read input
all_lines = STDIN.readlines.map(&:strip)

# Parse transfer penalty
transfer_penalty = all_lines[0].to_i

# First pass: collect segments and validate
segments = []
stations = Set.new
current_line_idx = 1
queries_line = nil

while current_line_idx < all_lines.length
  line = all_lines[current_line_idx]
  line_number = current_line_idx + 1

  if line == "QUERIES"
    queries_line = current_line_idx
    break
  end

  if line.empty?
    current_line_idx += 1
    next
  end

  # Parse segment
  fields = line.split

  if fields.length != 4
    puts "invalid segment at line #{line_number}"
    current_line_idx += 1
    next
  end

  line_name = fields[0]
  station_a = fields[1]
  station_b = fields[2]
  minutes_str = fields[3]

  # Validate segment
  valid = true

  if station_a == station_b
    valid = false
  elsif !minutes_str.match?(/^\d+$/)
    valid = false
  elsif minutes_str.length > 1 && minutes_str.start_with?("0")
    valid = false
  else
    minutes = minutes_str.to_i
    if minutes < 1 || minutes > 999
      valid = false
    end
  end

  if valid
    segments << { line: line_name, a: station_a, b: station_b, minutes: minutes }
    stations.add(station_a)
    stations.add(station_b)
  else
    puts "invalid segment at line #{line_number}"
  end

  current_line_idx += 1
end

# Build graph
graph = {}
stations.each { |s| graph[s] = [] }
segments.each do |seg|
  graph[seg[:a]] << { to: seg[:b], line: seg[:line], minutes: seg[:minutes] }
  graph[seg[:b]] << { to: seg[:a], line: seg[:line], minutes: seg[:minutes] }
end

# Second pass: process queries
if queries_line
  current_line_idx = queries_line + 1

  while current_line_idx < all_lines.length
    line = all_lines[current_line_idx]
    line_number = current_line_idx + 1

    if line.empty?
      current_line_idx += 1
      next
    end

    # Parse query
    fields = line.split

    if fields.length != 2
      puts "invalid query at line #{line_number}"
      current_line_idx += 1
      next
    end

    from = fields[0]
    to = fields[1]

    # Process query
    if !stations.include?(from)
      puts "#{from} -> #{to}: unknown station #{from}"
    elsif !stations.include?(to)
      puts "#{from} -> #{to}: unknown station #{to}"
    elsif from == to
      puts "#{from} -> #{to}: 0 min, 0 transfers"
    else
      # Find shortest path
      visited = Set.new
      pq = [[0, 0, [from], [], from]]
      best_path = nil

      while pq.any?
        pq.sort_by! { |state| [state[0], state[1], state[2], state[3]] }
        state = pq.shift

        cost, transfers, path_stations, path_lines, current = state

        if current == to
          best_path = { cost: cost, transfers: transfers, stations: path_stations, lines: path_lines }
          break
        end

        next if visited.include?(current)
        visited.add(current)

        graph[current].each do |edge|
          next_station = edge[:to]
          line_name = edge[:line]
          minutes = edge[:minutes]

          next if visited.include?(next_station)

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

      if best_path
        transfer_word = best_path[:transfers] == 1 ? "transfer" : "transfers"
        puts "#{from} -> #{to}: #{best_path[:cost]} min, #{best_path[:transfers]} #{transfer_word}"

        if best_path[:transfers] > 0
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

    current_line_idx += 1
  end
end

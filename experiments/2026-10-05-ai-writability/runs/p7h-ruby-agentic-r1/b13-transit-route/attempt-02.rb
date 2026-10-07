#!/usr/bin/env ruby

require 'set'

penalty = STDIN.readline.strip.to_i
segments = []
stations = Set.new
edges = {}  # edges[from][to] = [(line, time), ...]
line_num = 1

STDIN.each_line do |line|
  line_num += 1
  line = line.strip

  if line == "QUERIES"
    break
  end

  next if line.empty?

  parts = line.split

  if parts.length != 4
    puts "invalid segment at line #{line_num}"
  else
    line_name, a, b, time_str = parts

    if time_str !~ /^\d+$/ || (time_str =~ /^0[0-9]/ && time_str != "0")
      puts "invalid segment at line #{line_num}"
    elsif a == b
      puts "invalid segment at line #{line_num}"
    else
      time = time_str.to_i
      if time < 1 || time > 999
        puts "invalid segment at line #{line_num}"
      else
        stations.add(a)
        stations.add(b)
        edges[a] ||= {}
        edges[a][b] ||= []
        edges[a][b] << [line_name, time]
        edges[b] ||= {}
        edges[b][a] ||= []
        edges[b][a] << [line_name, time]
      end
    end
  end
end

# Process queries
STDIN.each_line do |line|
  line_num += 1
  line = line.strip
  next if line.empty?

  parts = line.split

  if parts.length != 2
    puts "invalid query at line #{line_num}"
  else
    from, to = parts

    if !stations.include?(from)
      puts "#{from} -> #{to}: unknown station #{from}"
    elsif !stations.include?(to)
      puts "#{from} -> #{to}: unknown station #{to}"
    elsif from == to
      puts "#{from} -> #{to}: 0 min, 0 transfers"
    else
      # Dijkstra with tie-breaking
      # State: (time, transfers, stations_list, lines_list, current, last_line)
      pq = [[0, 0, [from], [], from, nil]]
      visited = Set.new
      found = false

      while pq.any? && !found
        time, transfers, stations_list, lines_list, current, last_line = pq.shift

        state_key = [current, last_line]
        next if visited.include?(state_key)
        visited.add(state_key)

        if current == to
          # Found the destination
          transfer_word = transfers == 1 ? "transfer" : "transfers"
          puts "#{from} -> #{to}: #{time} min, #{transfers} #{transfer_word}"

          # Format route as legs
          if lines_list.any?
            legs = []
            i = 0
            while i < lines_list.length
              current_line = lines_list[i]
              leg_stations = [stations_list[i]]

              # Collect all consecutive segments with the same line
              while i + 1 < lines_list.length && lines_list[i + 1] == current_line
                i += 1
                leg_stations << stations_list[i]
              end

              legs << "#{current_line}: #{leg_stations.join(" > ")}"
              i += 1
            end

            puts "  " + legs.join("; ")
          end
          found = true
        else
          # Explore neighbors
          if edges[current]
            edges[current].each do |next_station, edges_list|
              edges_list.each do |next_line, next_time|
                new_transfers = transfers
                new_time = time + next_time

                if last_line && last_line != next_line
                  new_transfers += 1
                  new_time += penalty
                end

                new_stations = stations_list + [next_station]
                new_lines = lines_list + [next_line]

                new_state = [new_time, new_transfers, new_stations, new_lines, next_station, next_line]
                pq << new_state
              end
            end
          end

          # Sort by time, transfers, stations, lines
          pq.sort! { |a, b| [a[0], a[1], a[2], a[3]] <=> [b[0], b[1], b[2], b[3]] }
        end
      end

      unless found
        puts "#{from} -> #{to}: no route"
      end
    end
  end
end

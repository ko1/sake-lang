transfer_penalty = STDIN.readline.strip.to_i
input_line = 1

segments = []
known_stations = Set.new
queries_start = nil

while true
  input_line += 1
  line = STDIN.readline.chomp

  if line.strip.empty?
    next
  end

  if line == "QUERIES"
    queries_start = input_line
    break
  end

  parts = line.split

  if parts.length != 4
    puts "invalid segment at line #{input_line}"
    next
  end

  line_name = parts[0]
  from = parts[1]
  to = parts[2]
  minutes_str = parts[3]

  if minutes_str !~ /^\d+$/ || minutes_str =~ /^0\d/ || minutes_str.to_i < 1 || minutes_str.to_i > 999
    puts "invalid segment at line #{input_line}"
    next
  end

  if from == to
    puts "invalid segment at line #{input_line}"
    next
  end

  minutes = minutes_str.to_i
  segments << {line: line_name, from: from, to: to, minutes: minutes}
  known_stations.add(from)
  known_stations.add(to)
end

graph = {}
known_stations.each { |s| graph[s] = [] }
segments.each do |seg|
  graph[seg[:from]] << {to: seg[:to], line: seg[:line], minutes: seg[:minutes]}
  graph[seg[:to]] << {to: seg[:from], line: seg[:line], minutes: seg[:minutes]}
end

while true
  input_line += 1
  begin
    line = STDIN.readline.chomp
  rescue EOFError
    break
  end

  if line.strip.empty?
    next
  end

  parts = line.split

  if parts.length != 2
    puts "invalid query at line #{input_line}"
    next
  end

  from_station = parts[0]
  to_station = parts[1]

  if !known_stations.include?(from_station)
    puts "#{from_station} -> #{to_station}: unknown station #{from_station}"
    next
  end

  if !known_stations.include?(to_station)
    puts "#{from_station} -> #{to_station}: unknown station #{to_station}"
    next
  end

  if from_station == to_station
    puts "#{from_station} -> #{to_station}: 0 min, 0 transfers"
    next
  end

  pq = [[0, 0, [from_station], []]]
  found = false

  while pq.length > 0 && !found
    pq.sort! { |a, b| [a[0], a[1], a[2], a[3]] <=> [b[0], b[1], b[2], b[3]] }
    time, transfers, stations, lines = pq.shift
    current = stations[-1]

    if current == to_station
      found = true
      transfer_str = transfers == 1 ? "1 transfer" : "#{transfers} transfers"
      puts "#{from_station} -> #{to_station}: #{time} min, #{transfer_str}"

      legs = []
      if lines.length > 0
        current_line = lines[0]
        current_leg = [stations[0]]

        (1...stations.length).each do |i|
          if lines[i-1] == current_line
            current_leg << stations[i]
          else
            legs << "#{current_line}: #{current_leg.join(' > ')}"
            current_line = lines[i-1]
            current_leg = [stations[i]]
          end
        end
        legs << "#{current_line}: #{current_leg.join(' > ')}"
      end

      puts "  #{legs.join('; ')}"
      break
    end

    graph[current].each do |edge|
      next_station = edge[:to]
      line_name = edge[:line]
      minutes = edge[:minutes]

      new_transfers = transfers
      new_time = time + minutes

      if lines.length > 0 && lines[-1] != line_name
        new_transfers += 1
        new_time += transfer_penalty
      end

      new_stations = stations + [next_station]
      new_lines = lines + [line_name]

      pq << [new_time, new_transfers, new_stations, new_lines]
    end
  end

  if !found
    puts "#{from_station} -> #{to_station}: no route"
  end
end

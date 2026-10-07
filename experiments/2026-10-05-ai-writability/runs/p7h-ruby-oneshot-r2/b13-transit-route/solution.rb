penalty = STDIN.readline.strip.to_i
segments = []
known_stations = Set.new
line_num = 2

all_edges = []

loop do
  line = STDIN.readline.strip
  break if line == "QUERIES"

  next if line.empty?

  fields = line.split

  if fields.length != 4
    puts "invalid segment at line #{line_num}"
    line_num += 1
    next
  end

  line_name = fields[0]
  a = fields[1]
  b = fields[2]
  minutes = fields[3]

  # Check if minutes is valid integer
  if minutes !~ /^\d+$/ || minutes.to_i < 1 || minutes.to_i > 999 || minutes != minutes.to_i.to_s
    puts "invalid segment at line #{line_num}"
    line_num += 1
    next
  end

  if a == b
    puts "invalid segment at line #{line_num}"
    line_num += 1
    next
  end

  min_int = minutes.to_i
  known_stations.add(a)
  known_stations.add(b)
  all_edges << [line_name, a, b, min_int]

  line_num += 1
end

# Process queries
while true
  line = begin
    STDIN.readline.strip
  rescue EOFError
    break
  end

  next if line.empty?

  fields = line.split

  if fields.length != 2
    puts "invalid query at line #{line_num}"
    line_num += 1
    next
  end

  from = fields[0]
  to = fields[1]

  if !known_stations.include?(from)
    puts "#{from} -> #{to}: unknown station #{from}"
    line_num += 1
    next
  end

  if !known_stations.include?(to)
    puts "#{from} -> #{to}: unknown station #{to}"
    line_num += 1
    next
  end

  if from == to
    puts "#{from} -> #{to}: 0 min, 0 transfers"
    line_num += 1
    next
  end

  # Dijkstra's algorithm
  dist = {}
  pq = []

  # State: (cost, transfers, stations, lines, station, last_line)
  pq << [0, 0, [from], [], from, nil]
  dist[[from, nil]] = [0, 0, [from], []]

  result = nil

  while pq.any?
    pq.sort! { |a, b|
      if a[0] != b[0]
        a[0] <=> b[0]
      elsif a[1] != b[1]
        a[1] <=> b[1]
      elsif a[2] != b[2]
        a[2] <=> b[2]
      else
        a[3] <=> b[3]
      end
    }

    curr = pq.shift
    cost, transfers, stations, lines, station, last_line = curr

    if station == to
      result = [cost, transfers, stations, lines]
      break
    end

    state = [station, last_line]
    old = dist[state]
    if old && (old[0] < cost || (old[0] == cost && old[1] < transfers) || (old[0] == cost && old[1] == transfers && old[2] < stations) || (old[0] == cost && old[1] == transfers && old[2] == stations && old[3] < lines))
      next
    end

    # Explore neighbors
    all_edges.each do |line_name, a, b, min_int|
      next_station = nil
      if a == station
        next_station = b
      elsif b == station
        next_station = a
      else
        next
      end

      new_transfers = transfers
      new_cost = cost + min_int

      if last_line != line_name
        new_transfers += 1 if last_line != nil
        new_cost += penalty
      end

      new_stations = stations.dup
      new_stations << next_station

      new_lines = lines.dup
      new_lines << line_name

      new_state = [next_station, line_name]
      old_dist = dist[new_state]

      if !old_dist || new_cost < old_dist[0] || (new_cost == old_dist[0] && new_transfers < old_dist[1]) || (new_cost == old_dist[0] && new_transfers == old_dist[1] && new_stations < old_dist[2]) || (new_cost == old_dist[0] && new_transfers == old_dist[1] && new_stations == old_dist[2] && new_lines < old_dist[3])
        dist[new_state] = [new_cost, new_transfers, new_stations, new_lines]
        pq << [new_cost, new_transfers, new_stations, new_lines, next_station, line_name]
      end
    end
  end

  if result
    cost, transfers, stations, lines = result
    transfer_word = transfers == 1 ? "transfer" : "transfers"
    puts "#{from} -> #{to}: #{cost} min, #{transfers} #{transfer_word}"

    # Format the route - group consecutive segments with the same line
    route_parts = []
    i = 0
    while i < lines.length
      current_line = lines[i]
      segment = [stations[i], stations[i + 1]]

      j = i + 1
      while j < lines.length && lines[j] == current_line
        segment << stations[j + 1]
        j += 1
      end

      route_parts << "#{current_line}: #{segment.join(" > ")}"
      i = j
    end

    puts "  #{route_parts.join("; ")}"
  else
    puts "#{from} -> #{to}: no route"
  end

  line_num += 1
end

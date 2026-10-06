Edge = Struct.new(:line, :to, :minutes)

class Network
  def initialize(penalty)
    @penalty = penalty
    @adj = Hash.new { |h, k| h[k] = [] }
    @pair = Hash.new { |h, k| h[k] = [] }
  end

  def seg_lines(a, b, line) = @pair[[a, b].sort].find { |ns| ns.include?(line) }

  def shares?(names, a, b) = @pair[[a, b].sort].any? { |ns| (ns & names).any? }

  def add_all(names, a, b, minutes)
    names.each { |n| add(n, a, b, minutes) }
    @pair[[a, b].sort] << names
  end

  def add(line, a, b, minutes)
    @adj[a] << Edge.new(line, b, minutes)
    @adj[b] << Edge.new(line, a, minutes)
  end

  def known?(s) = @adj.key?(s)

  # Returns [time, transfers, stations, lines] or nil.
  def route(from, to)
    best = {}
    done = {}
    @adj[from].each do |e|
      key = [e.minutes, 0, [from, e.to], [e.line]]
      st = [e.to, e.line]
      best[st] = key if best[st].nil? || (key <=> best[st]) < 0
    end
    loop do
      cur = best.reject { |st, _| done[st] }.min_by { |_, k| k }
      return nil unless cur
      st, key = cur
      done[st] = true
      station, line = st
      return key if station == to
      time, transfers, stations, lines = key
      @adj[station].each do |e|
        next if stations.include?(e.to)
        change = e.line == line ? 0 : 1
        nk = [time + e.minutes + change * @penalty, transfers + change, stations + [e.to], lines + [e.line]]
        ns = [e.to, e.line]
        next if done[ns]
        best[ns] = nk if best[ns].nil? || (nk <=> best[ns]) < 0
      end
    end
  end
end

def legs(net, stations, lines)
  out = []
  i = 0
  while i < lines.size
    j = i
    j += 1 while j + 1 < lines.size && lines[j + 1] == lines[i]
    common = (i..j).map { |k| net.seg_lines(stations[k], stations[k + 1], lines[i]) }.reduce(:&).sort
    out << "#{common.join('/')}: #{stations[i..j + 1].join(' > ')}"
    i = j + 1
  end
  out.join("; ")
end

input = $stdin.readlines(chomp: true)
net = Network.new(input[0].to_i)
mode = :segments
input.each_with_index do |raw, idx|
  next if idx == 0
  n = idx + 1
  f = raw.split
  next if f.empty?
  if mode == :segments
    if raw == "QUERIES"
      mode = :queries
    elsif f.size == 4 && f[3].match?(/\A[1-9]\d*\z/) && f[3].to_i <= 999 && f[1] != f[2] &&
          (names = f[0].split("/", -1)).none?(&:empty?) && names.uniq.size == names.size &&
          !net.shares?(names, f[1], f[2])
      net.add_all(names, f[1], f[2], f[3].to_i)
    else
      puts "invalid segment at line #{n}"
    end
    next
  end
  if f.size != 2
    puts "invalid query at line #{n}"
    next
  end
  from, to = f
  head = "#{from} -> #{to}:"
  bad = [from, to].find { |s| !net.known?(s) }
  if bad
    puts "#{head} unknown station #{bad}"
  elsif from == to
    puts "#{head} 0 min, 0 transfers"
  elsif (r = net.route(from, to))
    time, transfers, stations, lines = r
    puts "#{head} #{time} min, #{transfers} transfer#{transfers == 1 ? '' : 's'}"
    puts "  #{legs(net, stations, lines)}"
  else
    puts "#{head} no route"
  end
end

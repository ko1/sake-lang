lines = $stdin.each_line.map(&:chomp)
P = lines[0].to_s.strip.to_i
segs = []
stations = {}
out = []
in_queries = false
(1...lines.size).each do |i|
  n = i + 1
  l = lines[i]
  next if l.strip.empty?
  if !in_queries
    if l.strip == "QUERIES"
      in_queries = true
      next
    end
    f = l.split
    if f.size == 4 && f[3] =~ /\A[1-9]\d{0,2}\z/ && f[1] != f[2]
      segs << [f[0], f[1], f[2], f[3].to_i]
      stations[f[1]] = true
      stations[f[2]] = true
    else
      out << "invalid segment at line #{n}"
    end
  else
    f = l.split
    if f.size == 2
      out << [:q, f[0], f[1]]
    else
      out << "invalid query at line #{n}"
    end
  end
end

# edges: state (station, line) -> list of [to_state, cost, segline]
edges = Hash.new { |h, k| h[k] = [] }
states = {}
segs.each do |ln, a, b, m|
  [[a, b], [b, a]].each do |u, v|
    # from any state at u, board line ln
    states[[u, ln]] = true
    states[[v, ln]] = true
  end
end
stations.each_key { |s| states[[s, nil]] = true }
states.each_key do |(u, l)|
  segs.each do |ln, a, b, m|
    [[a, b], [b, a]].each do |x, y|
      next unless x == u
      tr = l && l != ln
      c = m * 1000 + (tr ? P * 1000 + 1 : 0)
      edges[[u, l]] << [[y, ln], c]
    end
  end
end

def solve(src, dst, states, edges)
  inf = Float::INFINITY
  h = Hash.new(inf)
  states.each_key { |s| h[s] = 0 if s[0] == dst }
  loop do
    changed = false
    states.each_key do |s|
      next if s[0] == dst
      edges[s].each do |to, c|
        v = c + h[to]
        if v < h[s]
          h[s] = v
          changed = true
        end
      end
    end
    break unless changed
  end
  start = [src, nil]
  return nil if h[start] == inf
  tight = lambda do |s|
    edges[s].select { |to, c| c + h[to] == h[s] }
  end
  # station sequence
  frontier = [start]
  seq = [src]
  until frontier.any? { |s| s[0] == dst }
    cand = frontier.flat_map { |s| tight.call(s) }
    nx = cand.map { |to, _| to[0] }.min
    seq << nx
    frontier = cand.select { |to, _| to[0] == nx }.map(&:first).uniq
  end
  n = seq.size - 1
  # forward layers
  layers = [[start]]
  (1..n).each do |i|
    layers << layers[i - 1].flat_map { |s| tight.call(s).select { |to, _| to[0] == seq[i] }.map(&:first) }.uniq
  end
  good = Array.new(n + 1)
  good[n] = layers[n].select { |s| s[0] == dst }
  (n - 1).downto(0) do |i|
    good[i] = layers[i].select { |s| tight.call(s).any? { |to, _| to[0] == seq[i + 1] && good[i + 1].include?(to) } }
  end
  frontier = [start]
  lseq = []
  (1..n).each do |i|
    cand = frontier.flat_map { |s| tight.call(s).select { |to, _| to[0] == seq[i] && good[i].include?(to) }.map(&:first) }
    ln = cand.map { |t| t[1] }.min
    lseq << ln
    frontier = cand.select { |t| t[1] == ln }.uniq
  end
  [h[start], seq, lseq]
end

out.each do |o|
  unless o.is_a?(Array)
    puts o
    next
  end
  _, from, to = o
  head = "#{from} -> #{to}:"
  if !stations[from]
    puts "#{head} unknown station #{from}"
  elsif !stations[to]
    puts "#{head} unknown station #{to}"
  elsif from == to
    puts "#{head} 0 min, 0 transfers"
  else
    r = solve(from, to, states, edges)
    if r.nil?
      puts "#{head} no route"
    else
      cost, seq, lseq = r
      t, k = cost.divmod(1000)
      puts "#{head} #{t} min, #{k} transfer#{k == 1 ? '' : 's'}"
      legs = []
      lseq.each_with_index do |ln, i|
        if legs.empty? || legs.last[0] != ln
          legs << [ln, [seq[i]]]
        end
        legs.last[1] << seq[i + 1]
      end
      puts "  " + legs.map { |ln, ss| "#{ln}: #{ss.join(' > ')}" }.join("; ")
    end
  end
end

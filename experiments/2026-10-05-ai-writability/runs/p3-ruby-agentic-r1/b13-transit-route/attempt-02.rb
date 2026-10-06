lines = $stdin.read.split("\n", -1).map { |l| l.chomp("\r") }
pen = lines[0].to_i
adj = Hash.new { |h, k| h[k] = [] }
known = {}
out = []
inq = false
INF = [Float::INFINITY, 0]
add = ->(a, b) { [a[0] + b[0], a[1] + b[1]] }

solve = lambda do |from, to|
  succ = lambda do |s|
    u, l = s
    adj[u].map do |v, ln, m|
      ch = l && l != ln
      [[v, ln], [m + (ch ? pen : 0), ch ? 1 : 0]]
    end
  end
  start = [from, nil]
  states = [start]
  seen = { start => true }
  i = 0
  while i < states.size
    succ.(states[i]).each do |t, _|
      next if seen[t]
      seen[t] = true
      states << t
    end
    i += 1
  end
  d = Hash.new(INF)
  d[start] = [0, 0]
  loop do
    ch = false
    states.each do |s|
      next if d[s] == INF
      succ.(s).each do |t, c|
        nd = add.(d[s], c)
        if (nd <=> d[t]) < 0
          d[t] = nd; ch = true
        end
      end
    end
    break unless ch
  end
  h = Hash.new(INF)
  states.each { |s| h[s] = [0, 0] if s[0] == to }
  loop do
    ch = false
    states.each do |s|
      succ.(s).each do |t, c|
        next if h[t] == INF
        nh = add.(h[t], c)
        if (nh <=> h[s]) < 0
          h[s] = nh; ch = true
        end
      end
    end
    break unless ch
  end
  opt = h[start]
  return nil if opt == INF
  ok = ->(s, t, c) { d[s] != INF && h[t] != INF && add.(add.(d[s], c), h[t]) == opt }
  # phase 1: station sequence
  cur = [start]
  seq = [from]
  until seq.last == to
    cands = []
    cur.each { |s| succ.(s).each { |t, c| cands << t if ok.(s, t, c) } }
    mn = cands.map { |t| t[0] }.min
    cur = cands.select { |t| t[0] == mn }.uniq
    seq << mn
  end
  # phase 2: layered good states along seq
  layers = [[start]]
  (1...seq.size).each do |k|
    nxt = []
    layers[k - 1].each do |s|
      succ.(s).each { |t, c| nxt << t if t[0] == seq[k] && ok.(s, t, c) }
    end
    layers << nxt.uniq
  end
  good = Array.new(seq.size) { {} }
  layers.last.each { |s| good[-1][s] = true }
  (seq.size - 2).downto(0) do |k|
    layers[k].each do |s|
      good[k][s] = true if succ.(s).any? { |t, c| t[0] == seq[k + 1] && good[k + 1][t] && ok.(s, t, c) }
    end
  end
  s = start
  path = [s]
  (1...seq.size).each do |k|
    cs = succ.(s).select { |t, c| t[0] == seq[k] && good[k][t] && ok.(s, t, c) }.map(&:first)
    s = cs.min_by { |t| t[1] }
    path << s
  end
  [opt, path]
end

lines.each_with_index do |raw, idx|
  next if idx == 0
  n = idx + 1
  line = raw.strip
  next if line.empty?
  if !inq
    if line == "QUERIES"
      inq = true; next
    end
    f = line.split
    if f.size == 4 && f[3] =~ /\A[1-9]\d{0,2}\z/ && f[1] != f[2]
      m = f[3].to_i
      adj[f[1]] << [f[2], f[0], m]
      adj[f[2]] << [f[1], f[0], m]
      known[f[1]] = known[f[2]] = true
    else
      out << "invalid segment at line #{n}"
    end
  else
    f = line.split
    if f.size != 2
      out << "invalid query at line #{n}"; next
    end
    a, b = f
    if !known[a]
      out << "#{a} -> #{b}: unknown station #{a}"
    elsif !known[b]
      out << "#{a} -> #{b}: unknown station #{b}"
    elsif a == b
      out << "#{a} -> #{b}: 0 min, 0 transfers"
    else
      r = solve.(a, b)
      if r.nil?
        out << "#{a} -> #{b}: no route"
      else
        (t, k), path = r
        out << "#{a} -> #{b}: #{t} min, #{k} transfer#{k == 1 ? '' : 's'}"
        legs = []
        path[1..].each_with_index do |(st, ln), i|
          if legs.last && legs.last[0] == ln
            legs.last[1] << st
          else
            legs << [ln, [path[i][0], st]]
          end
        end
        out << "  " + legs.map { |ln, ss| "#{ln}: #{ss.join(' > ')}" }.join("; ")
      end
    end
  end
end
puts out

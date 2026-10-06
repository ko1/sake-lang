lines = $stdin.each_line.map { |l| l.chomp }
penalty = 0
out = []
segs = []
stations = {}
queries = []
in_queries = false
first = true
lines.each_with_index do |raw, i|
  n = i + 1
  line = raw.strip
  next if line.empty?
  if first
    first = false
    penalty = line.to_i
    next
  end
  if in_queries
    f = line.split(/ +/)
    if f.size == 2
      out << [:q, f[0], f[1]]
    else
      out << [:msg, "invalid query at line #{n}"]
    end
    next
  end
  if line == "QUERIES"
    in_queries = true
    next
  end
  f = line.split(/ +/)
  if f.size == 4 && f[3] =~ /\A[1-9]\d{0,2}\z/ && f[1] != f[2]
    segs << [f[0], f[1], f[2], f[3].to_i]
    stations[f[1]] = true
    stations[f[2]] = true
  else
    out << [:msg, "invalid segment at line #{n}"]
  end
end

adj = Hash.new { |h, k| h[k] = [] }
segs.each do |ln, a, b, m|
  adj[a] << [ln, b, m]
  adj[b] << [ln, a, m]
end

def route(adj, penalty, from, to)
  # state = [station, line]; label = [T, K, stations, lines]
  best = { [from, nil] => [0, 0, [from], []] }
  done = {}
  loop do
    cur = nil
    best.each do |st, lab|
      next if done[st]
      cur = st if cur.nil? || (lab <=> best[cur]) < 0
    end
    break if cur.nil?
    done[cur] = true
    lab = best[cur]
    adj[cur[0]].each do |ln, t, m|
      tr = !cur[1].nil? && cur[1] != ln
      nl = [lab[0] + m + (tr ? penalty : 0), lab[1] + (tr ? 1 : 0), lab[2] + [t], lab[3] + [ln]]
      key = [t, ln]
      next if done[key]
      best[key] = nl if best[key].nil? || (nl <=> best[key]) < 0
    end
  end
  cand = best.select { |st, _| st[0] == to }.values
  cand.min { |a, b| a <=> b }
end

results = []
out.each do |o|
  if o[0] == :msg
    results << o[1]
    next
  end
  _, from, to = o
  if !stations[from]
    results << "#{from} -> #{to}: unknown station #{from}"
  elsif !stations[to]
    results << "#{from} -> #{to}: unknown station #{to}"
  elsif from == to
    results << "#{from} -> #{to}: 0 min, 0 transfers"
  else
    r = route(adj, penalty, from, to)
    if r.nil?
      results << "#{from} -> #{to}: no route"
    else
      k = r[1]
      results << "#{from} -> #{to}: #{r[0]} min, #{k} #{k == 1 ? "transfer" : "transfers"}"
      legs = []
      r[3].each_with_index do |ln, j|
        if legs.empty? || legs[-1][0] != ln
          legs << [ln, [r[2][j]]]
        end
        legs[-1][1] << r[2][j + 1]
      end
      results << "  " + legs.map { |ln, ss| "#{ln}: #{ss.join(" > ")}" }.join("; ")
    end
  end
end
puts results

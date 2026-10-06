lines = $stdin.read.split("\n", -1).map { |l| l.chomp("\r") }
lines.pop if lines.last == ""
penalty = nil
edges = Hash.new { |h, k| h[k] = [] }
known = {}
out = []
mode = :seg
queries = []

def solve(edges, penalty, from, to)
  dist = { [from, nil] => [0, 0] }
  changed = true
  while changed
    changed = false
    dist.keys.each do |st|
      d = dist[st]
      s, pl = st
      edges[s].each do |nb, line, min|
        cost = min
        k = 0
        if pl && pl != line
          cost += penalty
          k = 1
        end
        nd = [d[0] + cost, d[1] + k]
        ns = [nb, line]
        if dist[ns].nil? || (nd <=> dist[ns]) < 0
          dist[ns] = nd
          changed = true
        end
      end
    end
  end
  best = nil
  dist.each { |(s, _), d| best = d if s == to && (best.nil? || (d <=> best) < 0) }
  return nil unless best
  memo = {}
  rec = lambda do |st|
    return memo[st] if memo.key?(st)
    d = dist[st]
    res = nil
    if st[0] == to && d == best
      res = [[], []]
    else
      s, pl = st
      edges[s].each do |nb, line, min|
        cost = min
        k = 0
        if pl && pl != line
          cost += penalty
          k = 1
        end
        nd = [d[0] + cost, d[1] + k]
        ns = [nb, line]
        next unless dist[ns] == nd && (nd[0] <= best[0])
        sub = rec.call(ns)
        next unless sub
        cand = [[nb] + sub[0], [line] + sub[1]]
        res = cand if res.nil? || (cand <=> res) < 0
      end
    end
    memo[st] = res
  end
  r = rec.call([from, nil])
  [best, r]
end

lines.each_with_index do |raw, i|
  n = i + 1
  line = raw.strip
  next if line.empty?
  if penalty.nil?
    penalty = line.to_i
    next
  end
  if mode == :seg
    if line == "QUERIES"
      mode = :query
      next
    end
    f = line.split(/ +/)
    ok = f.size == 4 && f[0] =~ /\A\w+\z/ && f[1] =~ /\A\w+\z/ && f[2] =~ /\A\w+\z/ &&
         f[3] =~ /\A[1-9]\d{0,2}\z/ && f[1] != f[2]
    if ok && f.all? { |x| x.ascii_only? }
      l, a, b, m = f
      m = m.to_i
      edges[a] << [b, l, m]
      edges[b] << [a, l, m]
      known[a] = true
      known[b] = true
    else
      out << "invalid segment at line #{n}"
    end
  else
    f = line.split(/\s+/)
    if f.size != 2
      out << "invalid query at line #{n}"
      next
    end
    from, to = f
    if !known[from]
      out << "#{from} -> #{to}: unknown station #{from}"
    elsif !known[to]
      out << "#{from} -> #{to}: unknown station #{to}"
    elsif from == to
      out << "#{from} -> #{to}: 0 min, 0 transfers"
    else
      res = solve(edges, penalty, from, to)
      if res.nil?
        out << "#{from} -> #{to}: no route"
      else
        best, (stations, ls) = res
        k = best[1]
        out << "#{from} -> #{to}: #{best[0]} min, #{k} transfer#{k == 1 ? '' : 's'}"
        full = [from] + stations
        legs = []
        ls.each_with_index do |l, j|
          if legs.empty? || legs.last[0] != l
            legs << [l, [full[j]]]
          end
          legs.last[1] << full[j + 1]
        end
        out << "  " + legs.map { |l, ss| "#{l}: #{ss.join(' > ')}" }.join("; ")
      end
    end
  end
end
puts out

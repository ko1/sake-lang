lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
P = lines[0].to_s.strip.to_i
NAME = /\A[A-Za-z0-9_]+\z/
adj = Hash.new { |h, k| h[k] = [] } # station => [[other, line, minutes]]
out = []
queries = []
in_q = false
lines.each_with_index do |raw, i|
  next if i == 0
  n = i + 1
  line = raw.strip
  next if line.empty?
  if !in_q
    if line == "QUERIES"
      in_q = true
      next
    end
    f = line.split
    ok = f.size == 4 && f[0] =~ NAME && f[1] =~ NAME && f[2] =~ NAME &&
         f[3] =~ /\A[1-9][0-9]{0,2}\z/ && f[1] != f[2]
    if ok
      l, a, b, m = f[0], f[1], f[2], f[3].to_i
      adj[a] << [b, l, m]
      adj[b] << [a, l, m]
    else
      out << [:msg, "invalid segment at line #{n}"]
    end
  else
    f = line.split
    if f.size != 2
      out << [:msg, "invalid query at line #{n}"]
    else
      out << [:q, f[0], f[1]]
    end
  end
end

def step_cost(prev, line, m)
  m * 1000 + (prev && prev != line ? P * 1000 + 1 : 0)
end

def solve(adj, from, to)
  inf = Float::INFINITY
  h = Hash.new(inf)
  # terminal: any state at target
  # backward relaxation over states (station, last line)
  states = []
  adj.each do |st, es|
    states << [st, nil] if st == from
    es.each { |(_, l, _)| states << [st, l] }
  end
  states.uniq!
  states.each { |s| h[s] = 0 if s[0] == to }
  changed = true
  while changed
    changed = false
    states.each do |s|
      next if s[0] == to
      adj[s[0]].each do |(b, l, m)|
        c = step_cost(s[1], l, m)
        d = h[[b, l]] + c
        if d < h[s]
          h[s] = d
          changed = true
        end
      end
    end
  end
  opt = h[[from, nil]]
  return nil if opt == inf
  frontier = { [from, nil] => [0, []] } # state => [g, lines]
  stations = [from]
  until stations.last == to
    cands = []
    frontier.each do |s, (g, ls)|
      adj[s[0]].each do |(b, l, m)|
        g2 = g + step_cost(s[1], l, m)
        next unless g2 + h[[b, l]] == opt
        cands << [b, l, g2, ls]
      end
    end
    nxt = cands.map(&:first).min
    nf = {}
    cands.each do |(b, l, g2, ls)|
      next unless b == nxt
      key = [b, l]
      nl = ls + [l]
      if !nf.key?(key) || (nl <=> nf[key][1]) < 0
        nf[key] = [g2, nl]
      end
    end
    frontier = nf
    stations << nxt
  end
  best = frontier.values.map { |(_, ls)| ls }.min { |x, y| x <=> y }
  [opt, stations, best]
end

res = []
out.each do |o|
  if o[0] == :msg
    res << o[1]
    next
  end
  from, to = o[1], o[2]
  head = "#{from} -> #{to}: "
  if !adj.key?(from)
    res << "#{head}unknown station #{from}"
  elsif !adj.key?(to)
    res << "#{head}unknown station #{to}"
  elsif from == to
    res << "#{head}0 min, 0 transfers"
  else
    r = solve(adj, from, to)
    if r.nil?
      res << "#{head}no route"
    else
      opt, sts, ls = r
      t = opt / 1000
      k = opt % 1000
      res << "#{head}#{t} min, #{k} #{k == 1 ? 'transfer' : 'transfers'}"
      legs = []
      ls.each_with_index do |l, i|
        if legs.empty? || legs.last[0] != l
          legs << [l, [sts[i]]]
        end
        legs.last[1] << sts[i + 1]
      end
      res << "  " + legs.map { |(l, ss)| "#{l}: #{ss.join(' > ')}" }.join("; ")
    end
  end
end
puts res

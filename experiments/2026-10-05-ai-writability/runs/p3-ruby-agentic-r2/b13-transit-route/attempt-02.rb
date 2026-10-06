lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
p_pen = lines[0].to_i
out = []
segs = []
inq = false
(1...lines.size).each do |i|
  n = i + 1
  l = lines[i].strip
  next if l.empty?
  if !inq
    if l == "QUERIES"
      inq = true
      next
    end
    f = l.split(" ")
    if f.size == 4 && f[0] =~ /\A\w+\z/ && f[1] =~ /\A\w+\z/ && f[2] =~ /\A\w+\z/ &&
       f[3] =~ /\A[1-9]\d{0,2}\z/ && f[1] != f[2]
      segs << [f[0], f[1], f[2], f[3].to_i]
    else
      out << [:msg, "invalid segment at line #{n}"]
    end
  else
    f = l.split(" ")
    if f.size == 2
      out << [:q, f[0], f[1]]
    else
      out << [:msg, "invalid query at line #{n}"]
    end
  end
end

known = {}
adj = Hash.new { |h, k| h[k] = [] }
segs.each do |ln, a, b, m|
  known[a] = known[b] = true
  adj[a] << [ln, b, m]
  adj[b] << [ln, a, m]
end

def edges(adj, st, pen)
  u, l = st
  adj[u].map do |ln, v, m|
    c = m * 1000 + ((l && l != ln) ? pen * 1000 + 1 : 0)
    [[v, ln], c, ln]
  end
end

res = []
out.each do |o|
  if o[0] == :msg
    res << o[1]
    next
  end
  from, to = o[1], o[2]
  hd = "#{from} -> #{to}"
  if !known[from]
    res << "#{hd}: unknown station #{from}"
    next
  elsif !known[to]
    res << "#{hd}: unknown station #{to}"
    next
  elsif from == to
    res << "#{hd}: 0 min, 0 transfers"
    next
  end
  src = [from, nil]
  fd = { src => 0 }
  changed = true
  while changed
    changed = false
    fd.keys.each do |s|
      edges(adj, s, p_pen).each do |s2, c, _|
        nd = fd[s] + c
        if !fd[s2] || nd < fd[s2]
          fd[s2] = nd
          changed = true
        end
      end
    end
  end
  fin = fd.keys.select { |s| s[0] == to }
  if fin.empty?
    res << "#{hd}: no route"
    next
  end
  opt = fd.values_at(*fin).min
  # backward dist
  bd = {}
  fd.each_key { |s| bd[s] = (s[0] == to ? 0 : nil) }
  changed = true
  while changed
    changed = false
    fd.each_key do |s|
      next if s[0] == to
      edges(adj, s, p_pen).each do |s2, c, _|
        next unless bd[s2]
        nd = bd[s2] + c
        if !bd[s] || nd < bd[s]
          bd[s] = nd
          changed = true
        end
      end
    end
  end
  valid = lambda do |s, s2, c|
    fd[s2] && bd[s2] && fd[s] + c == fd[s2] && fd[s2] + bd[s2] == opt
  end
  layers = [[src]]
  path_st = [from]
  until path_st.last == to
    cand = []
    layers.last.each do |s|
      edges(adj, s, p_pen).each { |s2, c, _| cand << s2 if valid.(s, s2, c) }
    end
    nxt = cand.map(&:first).min
    layers << cand.select { |s2| s2[0] == nxt }.uniq
    path_st << nxt
  end
  keep = Array.new(layers.size)
  keep[-1] = layers[-1]
  (layers.size - 2).downto(0) do |i|
    keep[i] = layers[i].select do |s|
      edges(adj, s, p_pen).any? { |s2, c, _| keep[i + 1].include?(s2) && valid.(s, s2, c) }
    end
  end
  curset = [src]
  lns = []
  (1...layers.size).each do |i|
    cand = []
    curset.each do |s|
      edges(adj, s, p_pen).each { |s2, c, ln| cand << [ln, s2] if keep[i].include?(s2) && valid.(s, s2, c) }
    end
    ml = cand.map(&:first).min
    lns << ml
    curset = cand.select { |ln, _| ln == ml }.map(&:last).uniq
  end
  t = opt / 1000
  k = opt % 1000
  res << "#{hd}: #{t} min, #{k} transfer#{k == 1 ? '' : 's'}"
  legs = []
  lns.each_with_index do |ln, i|
    if legs.empty? || legs.last[0] != ln
      legs << [ln, [path_st[i]]]
    end
    legs.last[1] << path_st[i + 1]
  end
  res << "  " + legs.map { |ln, st| "#{ln}: #{st.join(' > ')}" }.join("; ")
end
puts res

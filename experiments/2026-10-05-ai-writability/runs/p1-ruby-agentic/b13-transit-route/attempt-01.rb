lines = $stdin.each_line.map { |l| l.chomp }
pen = nil
segs = []
known = {}
out = []
in_q = false
lines.each_with_index do |raw, i|
  n = i + 1
  l = raw.strip
  next if l.empty?
  if pen.nil?
    pen = l.to_i
    next
  end
  f = l.split(/ +/)
  if !in_q
    if l == "QUERIES"
      in_q = true
      next
    end
    m = f[3]
    if f.size == 4 && m.match?(/\A[1-9]\d{0,2}\z/) && f[1] != f[2]
      segs << [f[0], f[1], f[2], m.to_i]
      known[f[1]] = true
      known[f[2]] = true
    else
      out << "invalid segment at line #{n}"
    end
  else
    if f.size != 2
      out << "invalid query at line #{n}"
      next
    end
    a, b = f
    if !known[a] then out << "#{a} -> #{b}: unknown station #{a}"; next end
    if !known[b] then out << "#{a} -> #{b}: unknown station #{b}"; next end
    if a == b then out << "#{a} -> #{b}: 0 min, 0 transfers"; next end
    adj = Hash.new { |h, k| h[k] = [] }
    segs.each do |ln, x, y, m|
      adj[x] << [ln, y, m]
      adj[y] << [ln, x, m]
    end
    best = {}
    start = [a, nil]
    best[start] = [0, 0, [a], []]
    queue = [start]
    until queue.empty?
      st = queue.shift
      s, last = st
      t, k, ss, ls = best[st]
      adj[s].each do |ln, v, m|
        tr = last && last != ln
        cand = [t + m + (tr ? pen : 0), k + (tr ? 1 : 0), ss + [v], ls + [ln]]
        ns = [v, ln]
        if best[ns].nil? || (cand <=> best[ns]) < 0
          best[ns] = cand
          queue << ns unless queue.include?(ns)
        end
      end
    end
    res = best.select { |(s, _), _| s == b }.values.min
    if res.nil?
      out << "#{a} -> #{b}: no route"
      next
    end
    t, k, ss, ls = res
    out << "#{a} -> #{b}: #{t} min, #{k} #{k == 1 ? 'transfer' : 'transfers'}"
    legs = []
    ls.each_with_index do |ln, j|
      if legs.empty? || legs.last[0] != ln
        legs << [ln, [ss[j], ss[j + 1]]]
      else
        legs.last[1] << ss[j + 1]
      end
    end
    out << "  " + legs.map { |ln, st| "#{ln}: #{st.join(' > ')}" }.join("; ")
  end
end
puts out

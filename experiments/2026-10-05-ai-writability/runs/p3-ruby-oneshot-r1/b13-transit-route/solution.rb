all = STDIN.read.split("\n", -1)
all.pop if all.last == ''
out = []
p_pen = nil
segs = []
queries = []
mode = :seg
all.each_with_index do |raw, i|
  n = i + 1
  line = raw.strip
  next if line.empty?
  if p_pen.nil?
    p_pen = line.to_i
    next
  end
  if mode == :seg
    if line == 'QUERIES'
      mode = :q
      next
    end
    f = line.split(/ +/)
    ok = f.size == 4 && f[0..2].all? { |x| x =~ /\A\w+\z/ } &&
         f[3] =~ /\A[1-9]\d{0,2}\z/ && f[1] != f[2]
    if ok
      segs << [f[0], f[1], f[2], f[3].to_i]
      out << nil
    else
      out << "invalid segment at line #{n}"
    end
  else
    f = line.split(/ +/)
    if f.size != 2
      out << "invalid query at line #{n}"
    else
      out << f
    end
  end
end
p_pen ||= 0

adj = Hash.new { |h, k| h[k] = [] }
segs.each do |l, a, b, m|
  adj[a] << [l, b, m]
  adj[b] << [l, a, m]
end
known = adj.keys

def best_route(from, to, adj, pen)
  best = { [from, nil] => [0, 0, [from], []] }
  changed = true
  while changed
    changed = false
    best.keys.each do |(u, l)|
      t, k, st, ln = best[[u, l]]
      adj[u].each do |m, v, mins|
        tr = (l && l != m) ? 1 : 0
        key = [t + mins + tr * pen, k + tr, st + [v], ln + [m]]
        cur = best[[v, m]]
        if cur.nil? || (key <=> cur) < 0
          best[[v, m]] = key
          changed = true
        end
      end
    end
  end
  cands = best.select { |(s, _), _| s == to }.values
  cands.min { |a, b| a <=> b }
end

out.each do |o|
  if o.nil?
    next
  elsif o.is_a?(String)
    puts o
    next
  end
  from, to = o
  if !known.include?(from)
    puts "#{from} -> #{to}: unknown station #{from}"
  elsif !known.include?(to)
    puts "#{from} -> #{to}: unknown station #{to}"
  elsif from == to
    puts "#{from} -> #{to}: 0 min, 0 transfers"
  else
    r = best_route(from, to, adj, p_pen)
    if r.nil?
      puts "#{from} -> #{to}: no route"
    else
      t, k, st, ln = r
      puts "#{from} -> #{to}: #{t} min, #{k} #{k == 1 ? 'transfer' : 'transfers'}"
      legs = []
      ln.each_with_index do |l, i|
        if legs.empty? || legs.last[0] != l
          legs << [l, [st[i]]]
        end
        legs.last[1] << st[i + 1]
      end
      puts "  " + legs.map { |l, s| "#{l}: #{s.join(' > ')}" }.join('; ')
    end
  end
end

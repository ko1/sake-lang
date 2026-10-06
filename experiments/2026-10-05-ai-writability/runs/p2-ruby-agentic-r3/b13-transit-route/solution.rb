require "set"
lines = $stdin.each_line.map { |l| l.chomp }
idx = 0
idx += 1 while idx < lines.size && lines[idx].strip.empty?
pen = lines[idx].to_i
idx += 1
segs = []
stations = Set.new
out = []
queries = false
NAME = /\A[A-Za-z0-9_]+\z/
while idx < lines.size
  raw = lines[idx]; n = idx + 1; idx += 1
  next if raw.strip.empty?
  if raw.strip == "QUERIES"
    queries = true; break
  end
  f = raw.split(" ")
  if f.size == 4 && f[0] =~ NAME && f[1] =~ NAME && f[2] =~ NAME && f[3] =~ /\A[1-9]\d{0,2}\z/ && f[1] != f[2]
    m = f[3].to_i
    segs << [f[1], f[2], f[0], m]
    segs << [f[2], f[1], f[0], m]
    stations << f[1] << f[2]
  else
    out << "invalid segment at line #{n}"
  end
end
adj = Hash.new { |h, k| h[k] = [] }
segs.each { |u, v, l, m| adj[u] << [v, l, m] }

def add(a, b) = [a[0] + b[0], a[1] + b[1]]

def solve(from, to, adj, pen)
  dist = {}
  adj[from].each do |v, l, m|
    s = [v, l]; c = [m, 0]
    dist[s] = c if dist[s].nil? || (c <=> dist[s]) < 0
  end
  done = Set.new
  loop do
    cur = dist.reject { |s, _| done.include?(s) }.min_by { |s, c| [c, s] }
    break unless cur
    s, c = cur
    done << s
    adj[s[0]].each do |v, l, m|
      tr = l != s[1] ? 1 : 0
      nc = add(c, [m + tr * pen, tr])
      t = [v, l]
      dist[t] = nc if dist[t].nil? || (nc <=> dist[t]) < 0
    end
  end
  term = dist.select { |s, _| s[0] == to }
  return nil if term.empty?
  d = term.values.min
  # optimal edges / goodness
  good = {}
  gf = lambda do |s|
    return good[s] if good.key?(s)
    r = dist[s] == d && s[0] == to
    adj[s[0]].each do |v, l, m|
      tr = l != s[1] ? 1 : 0
      t = [v, l]
      next unless dist[t] && add(dist[s], [m + tr * pen, tr]) == dist[t]
      r = true if gf.(t)
    end
    good[s] = r
  end
  succ = lambda do |s|
    adj[s[0]].filter_map do |v, l, m|
      tr = l != s[1] ? 1 : 0
      t = [v, l]
      t if dist[t] && add(dist[s], [m + tr * pen, tr]) == dist[t] && gf.(t)
    end.uniq
  end
  starts = adj[from].filter_map do |v, l, m|
    t = [v, l]
    t if dist[t] == [m, 0] && gf.(t)
  end.uniq
  term_p = ->(s) { s[0] == to && dist[s] == d }
  # station phase
  seq = [from]
  set = starts
  loop do
    nm = set.map { |s| s[0] }.min
    seq << nm
    set = set.select { |s| s[0] == nm }
    break if set.any?(&term_p)
    set = set.flat_map { |s| succ.(s) }.uniq
  end
  # layers with fixed station sequence
  layers = [set_l = starts.select { |s| s[0] == seq[1] }]
  (2...seq.size).each do |i|
    layers << layers.last.flat_map { |s| succ.(s) }.uniq.select { |s| s[0] == seq[i] }
  end
  layers[-1] = layers[-1].select(&term_p)
  (layers.size - 2).downto(0) do |i|
    layers[i] = layers[i].select { |s| succ.(s).any? { |t| layers[i + 1].include?(t) } }
  end
  lseq = []
  cur = layers[0]
  layers.each_with_index do |ly, i|
    cand = i == 0 ? ly : cur.flat_map { |s| succ.(s) }.uniq.select { |t| ly.include?(t) }
    ml = cand.map { |s| s[1] }.min
    lseq << ml
    cur = cand.select { |s| s[1] == ml }
  end
  [d, seq, lseq]
end

if queries
  while idx < lines.size
    raw = lines[idx]; n = idx + 1; idx += 1
    next if raw.strip.empty?
    f = raw.split(" ")
    if f.size != 2
      out << "invalid query at line #{n}"; next
    end
    a, b = f
    if !stations.include?(a)
      out << "#{a} -> #{b}: unknown station #{a}"
    elsif !stations.include?(b)
      out << "#{a} -> #{b}: unknown station #{b}"
    elsif a == b
      out << "#{a} -> #{b}: 0 min, 0 transfers"
    else
      r = solve(a, b, adj, pen)
      if r.nil?
        out << "#{a} -> #{b}: no route"
      else
        d, seq, lseq = r
        out << "#{a} -> #{b}: #{d[0]} min, #{d[1]} transfer#{d[1] == 1 ? '' : 's'}"
        legs = []
        lseq.each_with_index do |l, i|
          if legs.empty? || legs.last[0] != l
            legs << [l, [seq[i]]]
          end
          legs.last[1] << seq[i + 1]
        end
        out << "  " + legs.map { |l, st| "#{l}: #{st.join(' > ')}" }.join("; ")
      end
    end
  end
end
puts out

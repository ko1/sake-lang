lines = $stdin.read.to_s.split("\n").map { |l| l.chomp("\r") }
out = []
pen = nil
segs = []
queries = []
mode = :seg
name_re = /\A[A-Za-z0-9_]+\z/
lines.each_with_index do |raw, i|
  n = i + 1
  line = raw.strip
  next if line.empty?
  if pen.nil?
    pen = line.to_i
    next
  end
  if mode == :seg
    if line == "QUERIES"
      mode = :query
      next
    end
    f = line.split(" ")
    if f.size == 4 && f[0] =~ name_re && f[1] =~ name_re && f[2] =~ name_re &&
       f[1] != f[2] && f[3] =~ /\A[1-9]\d{0,2}\z/
      segs << [f[0], f[1], f[2], f[3].to_i]
    else
      out << "invalid segment at line #{n}"
    end
  else
    f = line.split(" ")
    if f.size != 2
      out << "invalid query at line #{n}"
    else
      queries << [f[0], f[1]]
      out << queries.size - 1 # placeholder
    end
  end
end
pen ||= 0
arcs = []
known = {}
segs.each do |l, a, b, m|
  arcs << [a, b, l, m]
  arcs << [b, a, l, m]
  known[a] = true
  known[b] = true
end

def solve(from, arcs, pen)
  best = { [from, nil] => [0, 0, [from], []] }
  changed = true
  while changed
    changed = false
    snapshot = best.to_a
    snapshot.each do |(u, l), lab|
      arcs.each do |a, b, ln, m|
        next unless a == u
        tr = (l && l != ln) ? 1 : 0
        cand = [lab[0] + m + tr * pen, lab[1] + tr, lab[2] + [b], lab[3] + [ln]]
        key = [b, ln]
        if best[key].nil? || (cand <=> best[key]) < 0
          best[key] = cand
          changed = true
        end
      end
    end
  end
  best
end

res = []
queries.each do |from, to|
  unless known[from]
    res << "#{from} -> #{to}: unknown station #{from}"
    next
  end
  unless known[to]
    res << "#{from} -> #{to}: unknown station #{to}"
    next
  end
  if from == to
    res << "#{from} -> #{to}: 0 min, 0 transfers"
    next
  end
  best = solve(from, arcs, pen)
  cands = best.select { |(s, _), _| s == to }.values
  if cands.empty?
    res << "#{from} -> #{to}: no route"
    next
  end
  t, k, st, ls = cands.min { |a, b| a <=> b }
  legs = []
  ls.each_with_index do |ln, i|
    if legs.empty? || legs.last[0] != ln
      legs << [ln, [st[i]]]
    end
    legs.last[1] << st[i + 1]
  end
  res << "#{from} -> #{to}: #{t} min, #{k} transfer#{k == 1 ? '' : 's'}"
  res << "  " + legs.map { |ln, s| "#{ln}: #{s.join(' > ')}" }.join("; ")
end
# merge: placeholders are integers in out; replace with the query's output lines
ri = 0
qi_lines = []
# recompute per-query line groups
groups = []
res.each do |r|
  if r.start_with?("  ")
    groups.last << r
  else
    groups << [r]
  end
end
final = out.map { |o| o.is_a?(Integer) ? groups[o] : o }.flatten
puts final

require "set"
NAME = /\A\w+\z/
raw = $stdin.each_line.map { |l| l.chomp }
pen = nil
segs = []
queries_mode = false
out = []
known = Set.new
adj = Hash.new { |h, k| h[k] = [] }
raw.each_with_index do |l, i|
  n = i + 1
  s = l.strip
  next if s.empty?
  if pen.nil?
    pen = s.to_i
    next
  end
  if !queries_mode
    if s == "QUERIES"
      queries_mode = true
      next
    end
    f = s.split(/ +/)
    if f.size == 4 && f.all? { |x| x =~ NAME && x !~ /[^\x00-\x7f]/ } && f[3] =~ /\A[1-9]\d{0,2}\z/ && f[1] != f[2]
      ln, a, b, m = f[0], f[1], f[2], f[3].to_i
      known << a << b
      adj[a] << [b, ln, m]
      adj[b] << [a, ln, m]
    else
      out << "invalid segment at line #{n}"
    end
  else
    f = s.split(/ +/)
    if f.size != 2
      out << "invalid query at line #{n}"
      next
    end
    from, to = f
    head = "#{from} -> #{to}:"
    if !known.include?(from)
      out << "#{head} unknown station #{from}"
    elsif !known.include?(to)
      out << "#{head} unknown station #{to}"
    elsif from == to
      out << "#{head} 0 min, 0 transfers"
    else
      # states [station, line]; cost [T, K]
      d = { [from, nil] => [0, 0] }
      done = Set.new
      loop do
        cur = d.reject { |k, _| done.include?(k) }.min_by { |_, v| v }
        break unless cur
        st, (t, k) = cur
        done << st
        u, l0 = st
        adj[u].each do |v, ln, m|
          tr = l0 && l0 != ln
          c = [t + m + (tr ? pen : 0), k + (tr ? 1 : 0)]
          ns = [v, ln]
          d[ns] = c if !d[ns] || (c <=> d[ns]) < 0
        end
      end
      ends = d.select { |(s2, _), _| s2 == to }
      if ends.empty?
        out << "#{head} no route"
        next
      end
      best = ends.values.min
      paths = []
      # backward enumeration over tight edges
      rec = lambda do |st, acc|
        if st[1].nil?
          paths << acc
          next
        end
        v, ln = st
        d.each do |(u, l0), (t0, k0)|
          adj[u].each do |v2, ln2, m|
            next unless v2 == v && ln2 == ln
            tr = l0 && l0 != ln
            next unless [t0 + m + (tr ? pen : 0), k0 + (tr ? 1 : 0)] == d[st]
            rec.call([u, l0], [[u, v, ln]] + acc)
          end
        end
      end
      ends.each { |st, v| rec.call(st, []) if v == best }
      pick = paths.min_by do |p|
        [[from] + p.map { |e| e[1] }, p.map { |e| e[2] }]
      end
      legs = []
      pick.each do |u, v, ln|
        if legs.empty? || legs[-1][0] != ln
          legs << [ln, [u, v]]
        else
          legs[-1][1] << v
        end
      end
      kk = best[1]
      out << "#{head} #{best[0]} min, #{kk} transfer#{kk == 1 ? "" : "s"}"
      out << "  " + legs.map { |ln, ss| "#{ln}: #{ss.join(" > ")}" }.join("; ")
    end
  end
end
puts out

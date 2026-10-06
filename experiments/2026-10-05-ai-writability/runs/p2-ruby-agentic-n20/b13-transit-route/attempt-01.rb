lines = $stdin.each_line.map(&:chomp)
first = lines.index { |l| !l.strip.empty? }
exit if first.nil?
penalty = lines[first].strip.to_i
adj = Hash.new { |h, k| h[k] = [] } # station => [[line, to, minutes]]
queries = false

def route(adj, from, to, penalty)
  best = {} # [station, line] => label
  work = []
  adj[from].each do |l, t, m|
    lab = [m, 0, [from, t], [l]]
    k = [t, l]
    if best[k].nil? || (lab <=> best[k]) < 0
      best[k] = lab
      work << k
    end
  end
  until work.empty?
    k = work.shift
    s, l = k
    lab = best[k]
    adj[s].each do |l2, t, m|
      sw = l2 != l
      nl = [lab[0] + m + (sw ? penalty : 0), lab[1] + (sw ? 1 : 0), lab[2] + [t], lab[3] + [l2]]
      k2 = [t, l2]
      if best[k2].nil? || (nl <=> best[k2]) < 0
        best[k2] = nl
        work << k2 unless work.include?(k2)
      end
    end
  end
  best.select { |k, _| k[0] == to }.values.min
end

lines.each_with_index do |raw, i|
  next if i <= first
  no = i + 1
  l = raw.strip
  next if l.empty?
  if !queries
    if l == "QUERIES"
      queries = true
      next
    end
    f = l.split(/ +/)
    if f.size == 4 && f[3] =~ /\A[1-9]\d{0,2}\z/ && f[1] != f[2]
      adj[f[1]] << [f[0], f[2], f[3].to_i]
      adj[f[2]] << [f[0], f[1], f[3].to_i]
    else
      puts "invalid segment at line #{no}"
    end
  else
    f = l.split(/ +/)
    if f.size != 2
      puts "invalid query at line #{no}"
      next
    end
    from, to = f
    if !adj.key?(from) then puts "#{from} -> #{to}: unknown station #{from}"
    elsif !adj.key?(to) then puts "#{from} -> #{to}: unknown station #{to}"
    elsif from == to then puts "#{from} -> #{to}: 0 min, 0 transfers"
    else
      r = route(adj, from, to, penalty)
      if r.nil?
        puts "#{from} -> #{to}: no route"
      else
        t, k, st, ls = r
        puts "#{from} -> #{to}: #{t} min, #{k} transfer#{k == 1 ? '' : 's'}"
        legs = []
        ls.each_with_index do |ln, j|
          if legs.empty? || legs[-1][0] != ln
            legs << [ln, [st[j]]]
          end
          legs[-1][1] << st[j + 1]
        end
        puts "  " + legs.map { |ln, ss| "#{ln}: #{ss.join(' > ')}" }.join("; ")
      end
    end
  end
end

lines = $stdin.read.to_s.b.split("\n", -1)
lines.pop if lines.last == ""
ws = /[ \t\r\f\v]+/n
hd = lines[0] ? lines[0].split(ws).reject(&:empty?) : []
unless hd.size == 4 && hd[0] == "depth" && hd[2] == "threshold" &&
       hd[1].match?(/\A[0-9]+\z/n) && hd[3].match?(/\A[0-9]+\z/n)
  puts "bad header"
  exit
end
depth = hd[1].to_i
thr = hd[3].to_i
# node: [:file, size] or [:dir, children_hash]
root = [:dir, {}]
lines.each_with_index do |raw, i|
  next if i == 0
  next if raw.match?(/\A[ \t\r\f\v]*\z/n)
  n = i + 1
  tk = raw.split(ws).reject(&:empty?)
  ok = tk.size == 2 && tk[0].match?(/\A[0-9]+\z/n) && tk[0].to_i <= 10**13
  comps = nil
  if ok
    comps = tk[1].split("/", -1)
    ok = comps.none? { |c| c.empty? || c == "." || c == ".." }
  end
  unless ok
    puts "line #{n}: malformed"
    next
  end
  path = tk[1]
  cur = root
  status = nil
  comps[0...-1].each do |c|
    nx = cur[1][c]
    break if nx.nil?
    if nx[0] == :file
      status = :conflict
      break
    end
    cur = nx
  end
  if status.nil? && cur.equal?(root) || status.nil?
    # walked fully only if all prefixes existed as dirs; otherwise nothing to conflict
    node = root
    comps[0...-1].each do |c|
      node = node[1][c]
      break if node.nil?
    end
    if node && comps.size >= 1
      last = node[1][comps[-1]]
      if last
        status = last[0] == :file ? :duplicate : :conflict
      end
    end
  end
  case status
  when :duplicate
    puts "line #{n}: duplicate #{path}"
    next
  when :conflict
    puts "line #{n}: conflict #{path}"
    next
  end
  node = root
  comps[0...-1].each do |c|
    node[1][c] ||= [:dir, {}]
    node = node[1][c]
  end
  node[1][comps[-1]] = [:file, tk[0].to_i]
end

def total(node)
  node[0] == :file ? node[1] : node[1].values.sum { |c| total(c) }
end

def human(s)
  return "#{s}B" if s < 1024
  units = [[1024, "K"], [1024**2, "M"], [1024**3, "G"]]
  idx = 0
  units.each_with_index { |(u, _), j| idx = j if u <= s }
  u, l = units[idx]
  t = (20 * s + u) / (2 * u)
  return "#{t / 10}.#{t % 10}#{l}" if t < 100
  nn = (2 * s + u) / (2 * u)
  return "1.0#{units[idx + 1][1]}" if nn == 1024 && idx < 2
  "#{nn}#{l}"
end

def show(size, d, name)
  puts format("%6s  %s%s", human(size), "  " * d, name)
end

def walk(node, d, depth, thr)
  return if d >= depth
  ents = node[1].map { |name, c| [name, c, total(c)] }
  ents.sort_by! { |name, _, sz| [-sz, name] }
  small = 0
  smallsum = 0
  ents.each do |name, c, sz|
    if sz < thr
      small += 1
      smallsum += sz
      next
    end
    show(sz, d + 1, c[0] == :dir ? "#{name}/" : name)
    walk(c, d + 1, depth, thr) if c[0] == :dir
  end
  show(smallsum, d + 1, "(#{small} smaller)") if small > 0
end

show(total(root), 0, ".")
walk(root, 0, depth, thr)

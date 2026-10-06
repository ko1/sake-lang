lines = $stdin.read.each_line.map { |l| l.chomp.chomp("\r") }
h = (lines[0] || "").split
unless h.size == 4 && h[0] == "depth" && h[2] == "threshold" && h[1] =~ /\A\d+\z/ && h[3] =~ /\A\d+\z/
  puts "bad header"
  exit
end
maxd = h[1].to_i
thr = h[3].to_i
# node: Hash => dir (name => node), Integer => file size
root = {}
(1...lines.size).each do |i|
  l = lines[i]
  n = i + 1
  next if l.strip.empty?
  tk = l.split
  comps = tk.size == 2 ? tk[1].split("/", -1) : nil
  if tk.size != 2 || tk[0] !~ /\A\d+\z/ || tk[0].to_i > 10**13 ||
     comps.any? { |c| c.empty? || c == "." || c == ".." }
    puts "line #{n}: malformed"
    next
  end
  size = tk[0].to_i
  node = root
  status = :ok
  comps.each_with_index do |c, idx|
    last = idx == comps.size - 1
    nx = node[c]
    if nx.nil?
      break
    elsif last
      status = nx.is_a?(Hash) ? :conflict : :dup
    elsif !nx.is_a?(Hash)
      status = :conflict
      break
    else
      node = nx
    end
    break if status != :ok
    node = nx
  end
  case status
  when :dup
    puts "line #{n}: duplicate #{tk[1]}"
    next
  when :conflict
    puts "line #{n}: conflict #{tk[1]}"
    next
  end
  node = root
  comps[0...-1].each do |c|
    node[c] ||= {}
    node = node[c]
  end
  node[comps.last] = size
end

def total(nd)
  nd.is_a?(Hash) ? nd.values.sum { |v| total(v) } : nd
end

def fmt(s)
  return "#{s}B" if s < 1024
  units = [[1024**3, "G"], [1024**2, "M"], [1024, "K"]]
  idx = units.index { |u, _| u <= s }
  u, ch = units[idx]
  t = (s * 20 + u) / (2 * u)
  return "#{t / 10}.#{t % 10}#{ch}" if t < 100
  nn = (s * 2 + u) / (2 * u)
  if nn == 1024 && ch != "G"
    return "1.0#{units[idx - 1][1]}"
  end
  "#{nn}#{ch}"
end

def line(size, depth, name)
  puts format("%6s  %s%s", fmt(size), "  " * depth, name)
end

def walk(dir, depth, maxd, thr)
  ents = dir.map { |name, nd| [name, nd, total(nd)] }
  ents.sort_by! { |name, _, sz| [-sz, name] }
  small = 0
  smallsum = 0
  ents.each do |name, nd, sz|
    if sz < thr
      small += 1
      smallsum += sz
      next
    end
    if nd.is_a?(Hash)
      line(sz, depth, "#{name}/")
      walk(nd, depth + 1, maxd, thr) if depth < maxd
    else
      line(sz, depth, name)
    end
  end
  line(smallsum, depth, "(#{small} smaller)") if small > 0
end

line(total(root), 0, ".")
walk(root, 1, maxd, thr) if maxd > 0

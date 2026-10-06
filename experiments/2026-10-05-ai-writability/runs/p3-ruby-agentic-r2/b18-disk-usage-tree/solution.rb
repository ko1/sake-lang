lines = $stdin.read.split("\n")
hd = (lines[0] || "").split
unless hd.size == 4 && hd[0] == "depth" && hd[2] == "threshold" && hd[1] =~ /\A\d+\z/ && hd[3] =~ /\A\d+\z/
  puts "bad header"; exit
end
maxd = hd[1].to_i; thr = hd[3].to_i
root = { dir: true, kids: {} }
files = {}
lines[1..].each_with_index do |raw, i|
  n = i + 2
  ln = raw.chomp("\r")
  next if ln.strip.empty?
  t = ln.split
  comps = t.size == 2 ? t[1].split("/", -1) : nil
  if t.size != 2 || t[0] !~ /\A\d+\z/ || t[0].to_i > 10**13 ||
     comps.any? { |c| c.empty? || c == "." || c == ".." }
    puts "line #{n}: malformed"; next
  end
  path = t[1]
  if files[path]
    puts "line #{n}: duplicate #{path}"; next
  end
  conflict = false
  node = root
  comps.each_with_index do |c, j|
    nx = node[:kids][c]
    break unless nx
    if !nx[:dir] && j < comps.size - 1 then conflict = true; break end
    if j == comps.size - 1 && nx[:dir] then conflict = true; break end
    node = nx
  end
  if conflict
    puts "line #{n}: conflict #{path}"; next
  end
  files[path] = true
  node = root
  comps.each_with_index do |c, j|
    if j == comps.size - 1
      node[:kids][c] = { dir: false, size: t[0].to_i }
    else
      node = (node[:kids][c] ||= { dir: true, kids: {} })
    end
  end
end
def size_of(nd)
  nd[:size] ||= nd[:kids].values.sum { |k| size_of(k) }
end
def fmt(s)
  return "#{s}B" if s < 1024
  units = [[1024**3, "G"], [1024**2, "M"], [1024, "K"]]
  idx = units.index { |u, _| u <= s }
  u, l = units[idx]
  t = (s * 20 + u) / (2 * u)
  return "#{t / 10}.#{t % 10}#{l}" if t < 100
  n = (2 * s + u) / (2 * u)
  if n == 1024 && l != "G"
    return "1.0#{units[idx - 1][1]}"
  end
  "#{n}#{l}"
end
def show(nd, name, depth, maxd, thr)
  puts format("%6s  %s%s", fmt(size_of(nd)), "  " * depth, name)
  walk(nd, depth, maxd, thr)
end
def walk(nd, depth, maxd, thr)
  return if depth >= maxd
  ents = nd[:kids].map { |k, v| [k, v, size_of(v)] }.sort_by { |k, _, s| [-s, k.b] }
  small = []
  ents.each do |k, v, s|
    if s < thr then small << s; next end
    puts format("%6s  %s%s", fmt(s), "  " * (depth + 1), v[:dir] ? "#{k}/" : k)
    walk(v, depth + 1, maxd, thr) if v[:dir]
  end
  unless small.empty?
    puts format("%6s  %s%s", fmt(small.sum), "  " * (depth + 1), "(#{small.size} smaller)")
  end
end
show(root, ".", 0, maxd, thr)

lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
h = (lines[0] || "").split
unless h.size == 4 && h[0] == "depth" && h[2] == "threshold" && h[1] =~ /\A\d+\z/ && h[3] =~ /\A\d+\z/
  puts "bad header"
  exit
end
maxd = h[1].to_i
thr = h[3].to_i
files = {}
dirs = {}
tree = { size: 0, kids: {}, dir: true }
lines[1..].each_with_index do |raw, i|
  ln = raw.chomp
  next if ln.strip.empty?
  n = i + 2
  tk = ln.split
  ok = tk.size == 2 && tk[0] =~ /\A\d+\z/ && tk[0].to_i <= 10**13
  comps = ok ? tk[1].split("/", -1) : []
  ok &&= comps.none? { |c| c.empty? || c == "." || c == ".." }
  unless ok
    puts "line #{n}: malformed"
    next
  end
  path = tk[1]
  if files[path]
    puts "line #{n}: duplicate #{path}"
    next
  end
  conflict = dirs[path] || (1...comps.size).any? { |k| files[comps[0, k].join("/")] }
  if conflict
    puts "line #{n}: conflict #{path}"
    next
  end
  files[path] = true
  size = tk[0].to_i
  node = tree
  node[:size] += size
  comps.each_with_index do |c, k|
    last = k == comps.size - 1
    if last
      node[:kids][c] = { size: size, kids: nil, dir: false }
    else
      dirs[comps[0..k].join("/")] = true
      node = (node[:kids][c] ||= { size: 0, kids: {}, dir: true })
      node[:size] += size
    end
  end
end
def fmt(s)
  return "#{s}B" if s < 1024
  units = [[1024**3, "G"], [1024**2, "M"], [1024, "K"]]
  idx = units.index { |u, _| u <= s }
  u, l = units[idx]
  t = (s * 10 + u / 2) / u
  return "#{t / 10}.#{t % 10}#{l}" if t < 100
  n = (s + u / 2) / u
  if n == 1024 && l != "G"
    return "1.0#{units[idx - 1][1]}"
  end
  "#{n}#{l}"
end
def line(size, depth, name)
  puts format("%6s  %s%s", fmt(size), "  " * depth, name)
end
walk = lambda do |node, depth|
  return if depth >= $maxd
  ents = node[:kids].sort_by { |nm, e| [-e[:size], nm] }
  small = 0
  cnt = 0
  ents.each do |nm, e|
    if e[:size] < $thr
      small += e[:size]
      cnt += 1
      next
    end
    line(e[:size], depth + 1, e[:dir] ? "#{nm}/" : nm)
    walk.(e, depth + 1) if e[:dir]
  end
  line(small, depth + 1, "(#{cnt} smaller)") if cnt > 0
end
$maxd = maxd
$thr = thr
line(tree[:size], 0, ".")
walk.(tree, 0)

lines = $stdin.binmode.read.each_line.map(&:chomp)
h = (lines[0] || "").split
unless h.size == 4 && h[0] == "depth" && h[2] == "threshold" && h[1] =~ /\A\d+\z/ && h[3] =~ /\A\d+\z/
  puts "bad header"; exit
end
maxd = h[1].to_i
thr = h[3].to_i
files = {}
dirs = { "" => true }
lines[1..].to_a.each_with_index do |ln, i|
  no = i + 2
  w = ln.split
  next if w.empty?
  ok = w.size == 2 && w[0] =~ /\A\d+\z/ && w[0].to_i <= 10**13
  comps = ok ? w[1].split("/", -1) : nil
  ok &&= comps.none? { |c| c.empty? || c == "." || c == ".." }
  unless ok
    puts "line #{no}: malformed"; next
  end
  path = w[1]
  if files.key?(path)
    puts "line #{no}: duplicate #{path}"; next
  end
  conflict = dirs.key?(path)
  (1...comps.size).each { |k| conflict ||= files.key?(comps[0, k].join("/")) }
  if conflict
    puts "line #{no}: conflict #{path}"; next
  end
  files[path] = w[0].to_i
  (1...comps.size).each { |k| dirs[comps[0, k].join("/")] = true }
end

def fmt(s)
  return "#{s}B" if s < 1024
  units = [["K", 1024], ["M", 1024**2], ["G", 1024**3]]
  idx = units.rindex { |_, u| u <= s }
  l, u = units[idx]
  t = (s * 10 * 2 + u) / (2 * u)
  return "#{t / 10}.#{t % 10}#{l}" if t < 100
  n = (s * 2 + u) / (2 * u)
  if n == 1024 && idx < 2
    "1.0#{units[idx + 1][0]}"
  else
    "#{n}#{l}"
  end
end

tree = { kids: {} }
files.each do |p, s|
  node = tree
  comps = p.split("/")
  comps.each_with_index do |c, i|
    node = (node[:kids][c] ||= { kids: {}, name: c })
    node[:file] = true if i == comps.size - 1
    node[:size] = s if i == comps.size - 1
  end
end
sz = nil
sz = lambda do |n|
  n[:size] ||= n[:kids].each_value.sum { |k| sz.(k) }
end
sz.(tree)
def line(size, depth, name) = puts(format("%6s  %s%s", fmt(size), "  " * depth, name))
line(tree[:size], 0, ".")
walk = nil
walk = lambda do |n, depth|
  return if depth >= maxd
  ents = n[:kids].values.sort_by { |k| [-k[:size], k[:name].b] }
  small = ents.select { |k| k[:size] < thr }
  (ents - small).each do |k|
    line(k[:size], depth + 1, k[:file] ? k[:name] : k[:name] + "/")
    walk.(k, depth + 1)
  end
  line(small.sum { |k| k[:size] }, depth + 1, "(#{small.size} smaller)") unless small.empty?
end
walk.(tree, 0)

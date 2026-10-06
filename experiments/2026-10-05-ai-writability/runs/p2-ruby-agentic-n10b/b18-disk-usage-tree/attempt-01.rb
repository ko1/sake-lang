lines = $stdin.each_line.map(&:chomp)
h = (lines[0] || "").split
unless h.size == 4 && h[0] == "depth" && h[2] == "threshold" && h[1] =~ /\A\d+\z/ && h[3] =~ /\A\d+\z/
  puts "bad header"
  exit
end
maxd = h[1].to_i
thr = h[3].to_i
files = {}
dirs = {}
out = []
lines.each_with_index do |l, i|
  next if i == 0
  n = i + 1
  f = l.split
  next if f.empty?
  comps = f.size == 2 ? f[1].split("/", -1) : nil
  if f.size != 2 || f[0] !~ /\A\d+\z/ || f[0].to_i > 10**13 ||
     comps.any? { |c| c.empty? || c == "." || c == ".." }
    out << "line #{n}: malformed"
    next
  end
  path = f[1]
  if files.key?(path)
    out << "line #{n}: duplicate #{path}"
    next
  end
  prefs = (1...comps.size).map { |k| comps[0, k].join("/") }
  if prefs.any? { |p| files.key?(p) } || dirs.key?(path)
    out << "line #{n}: conflict #{path}"
    next
  end
  files[path] = f[0].to_i
  prefs.each { |p| dirs[p] = true }
end

root = { kids: {}, size: 0, dir: true }
files.each do |path, sz|
  cs = path.split("/")
  node = root
  node[:size] += sz
  cs.each_with_index do |c, k|
    last = k == cs.size - 1
    node[:kids][c] ||= last ? { size: 0, dir: false } : { kids: {}, size: 0, dir: true }
    node = node[:kids][c]
    node[:size] += sz
  end
end

def human(s)
  return "#{s}B" if s < 1024
  units = [["K", 1024], ["M", 1024**2], ["G", 1024**3]]
  idx = units.rindex { |_, u| u <= s }
  letter, u = units[idx]
  t = (s * 10 * 2 + u) / (2 * u)
  return "#{t / 10}.#{t % 10}#{letter}" if t < 100
  n = (s * 2 + u) / (2 * u)
  if n == 1024 && letter != "G"
    "1.0#{units[idx + 1][0]}"
  else
    "#{n}#{letter}"
  end
end

def line(size, depth, name) = format("%6s  %s%s", human(size), "  " * depth, name)

out << line(root[:size], 0, ".")
walk = lambda do |node, depth|
  return if depth >= maxd
  ents = node[:kids].sort_by { |nm, k| [-k[:size], nm] }
  small = ents.select { |_, k| k[:size] < thr }
  ents.each do |nm, k|
    next if k[:size] < thr
    out << line(k[:size], depth + 1, k[:dir] ? "#{nm}/" : nm)
    walk.call(k, depth + 1) if k[:dir]
  end
  unless small.empty?
    out << line(small.sum { |_, k| k[:size] }, depth + 1, "(#{small.size} smaller)")
  end
end
walk.call(root, 0)
puts out

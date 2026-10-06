lines = $stdin.readlines.map(&:chomp)
h = (lines[0] || "").split
unless h.size == 4 && h[0] == "depth" && h[2] == "threshold" &&
       h[1].match?(/\A\d+\z/) && h[3].match?(/\A\d+\z/)
  puts "bad header"
  exit
end
maxd = h[1].to_i
thr = h[3].to_i

files = {}
dirs = {}
(lines[1..] || []).each_with_index do |ln, i|
  num = i + 2
  next if ln.strip.empty?
  tk = ln.split
  comps = tk.size == 2 ? tk[1].split("/", -1) : nil
  if tk.size != 2 || !tk[0].match?(/\A\d+\z/) || tk[0].to_i > 10**13 ||
     comps.any? { |c| c.empty? || c == "." || c == ".." }
    puts "line #{num}: malformed"
    next
  end
  path = tk[1]
  if files.key?(path)
    puts "line #{num}: duplicate #{path}"
    next
  end
  prefixes = (1...comps.size).map { |k| comps[0, k].join("/") }
  if prefixes.any? { |p| files.key?(p) } || dirs.key?(path)
    puts "line #{num}: conflict #{path}"
    next
  end
  files[path] = tk[0].to_i
  prefixes.each { |p| dirs[p] = true }
end

# node: [size, children hash or nil]
root = [0, {}]
files.each do |path, sz|
  comps = path.split("/")
  node = root
  node[0] += sz
  comps.each_with_index do |c, idx|
    if idx == comps.size - 1
      node[1][c] = [sz, nil]
    else
      node[1][c] ||= [0, {}]
      node = node[1][c]
      node[0] += sz
    end
  end
end

def rnd(a, b)
  (2 * a + b) / (2 * b)
end

def fmt_size(s)
  return "#{s}B" if s < 1024
  units = [[1024, "K"], [1024**2, "M"], [1024**3, "G"]]
  idx = 0
  units.each_with_index { |(u, _), k| idx = k if u <= s }
  u, ch = units[idx]
  t = rnd(s * 10, u)
  return "#{t / 10}.#{t % 10}#{ch}" if t < 100
  n = rnd(s, u)
  if n == 1024 && idx < 2
    "1.0#{units[idx + 1][1]}"
  else
    "#{n}#{ch}"
  end
end

def line(size, depth, name)
  format("%6s  %s%s", fmt_size(size), "  " * depth, name)
end

walk = lambda do |node, depth|
  ents = node[1].sort_by { |name, (sz, _)| [-sz, name] }
  small = 0
  small_n = 0
  ents.each do |name, ch|
    if ch[0] < thr
      small += ch[0]
      small_n += 1
      next
    end
    if ch[1]
      puts line(ch[0], depth, name + "/")
      walk.(ch, depth + 1) if depth < maxd
    else
      puts line(ch[0], depth, name)
    end
  end
  puts line(small, depth, "(#{small_n} smaller)") if small_n > 0
end

puts line(root[0], 0, ".")
walk.(root, 1) if maxd > 0

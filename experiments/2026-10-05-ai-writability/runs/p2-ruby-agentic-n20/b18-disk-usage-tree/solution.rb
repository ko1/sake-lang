lines = $stdin.each_line.map(&:chomp)
h = (lines[0] || "").split(/\s+/).reject(&:empty?)
unless h.size == 4 && h[0] == "depth" && h[2] == "threshold" && h[1] =~ /\A\d+\z/ && h[3] =~ /\A\d+\z/
  puts "bad header"
  exit
end
maxd = h[1].to_i
thr = h[3].to_i

def rnd(num, den) = (2 * num + den) / (2 * den)

def size_str(s)
  return "#{s}B" if s < 1024
  units = [[1024**3, "G"], [1024**2, "M"], [1024, "K"]]
  idx = units.index { |u, _| u <= s }
  u, l = units[idx]
  t = rnd(s * 10, u)
  return "#{t / 10}.#{t % 10}#{l}" if t < 100
  n = rnd(s, u)
  if n == 1024 && l != "G"
    "1.0#{units[idx - 1][1]}"
  else
    "#{n}#{l}"
  end
end

files = {}
dirs = {}
root = { kids: {}, size: 0 } # node: dir => {kids:, size:}, file => size Integer

lines.each_with_index do |text, i|
  next if i == 0
  no = i + 1
  next if text.strip.empty?
  f = text.split(/\s+/).reject(&:empty?)
  comps = f.size == 2 ? f[1].split("/", -1) : nil
  unless f.size == 2 && f[0] =~ /\A\d+\z/ && f[0].to_i <= 10**13 &&
         comps.none? { |c| c.empty? || c == "." || c == ".." }
    puts "line #{no}: malformed"
    next
  end
  path = f[1]
  if files.key?(path)
    puts "line #{no}: duplicate #{path}"
    next
  end
  prefixes = (1...comps.size).map { |k| comps[0, k].join("/") }
  if prefixes.any? { |p| files.key?(p) } || dirs.key?(path)
    puts "line #{no}: conflict #{path}"
    next
  end
  size = f[0].to_i
  files[path] = size
  prefixes.each { |p| dirs[p] = true }
  node = root
  node[:size] += size
  comps[0...-1].each do |c|
    node = (node[:kids][c] ||= { kids: {}, size: 0 })
    node[:size] += size
  end
  node[:kids][comps[-1]] = size
end

sz = ->(x) { x.is_a?(Integer) ? x : x[:size] }
puts format("%6s  %s", size_str(root[:size]), ".")

show = lambda do |node, depth|
  ents = node[:kids].sort_by { |name, x| [-sz.call(x), name.b] }
  small = []
  ents.each do |name, x|
    if sz.call(x) < thr
      small << x
      next
    end
    dir = !x.is_a?(Integer)
    puts format("%6s  %s%s", size_str(sz.call(x)), "  " * depth, dir ? "#{name}/" : name)
    show.call(x, depth + 1) if dir && depth < maxd
  end
  unless small.empty?
    puts format("%6s  %s%s", size_str(small.sum { |x| sz.call(x) }), "  " * depth, "(#{small.size} smaller)")
  end
end
show.call(root, 1) if maxd > 0

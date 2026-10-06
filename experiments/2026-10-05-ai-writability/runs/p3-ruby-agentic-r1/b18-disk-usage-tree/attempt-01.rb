lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
hd = (lines[0] || "").split
unless hd.size == 4 && hd[0] == "depth" && hd[2] == "threshold" && hd[1] =~ /\A\d+\z/ && hd[3] =~ /\A\d+\z/
  puts "bad header"
  exit
end
depth = hd[1].to_i
thr = hd[3].to_i
files = {}
dirs = {}
root = {dir: true, kids: {}}
lines[1..].each_with_index do |l, i|
  no = i + 2
  l = l.chomp("\r")
  next if l.strip.empty?
  tk = l.split
  if tk.size != 2 || tk[0] !~ /\A\d+\z/ || tk[0].to_i > 10**13
    puts "line #{no}: malformed"; next
  end
  path = tk[1]
  comps = path.split("/", -1)
  if comps.any? { |c| c.empty? || c == "." || c == ".." }
    puts "line #{no}: malformed"; next
  end
  if files.key?(path)
    puts "line #{no}: duplicate #{path}"; next
  end
  if dirs.key?(path) || (1...comps.size).any? { |k| files.key?(comps[0, k].join("/")) }
    puts "line #{no}: conflict #{path}"; next
  end
  files[path] = true
  node = root
  comps[0..-2].each_with_index do |c, k|
    dirs[comps[0..k].join("/")] = true
    node = (node[:kids][c] ||= {dir: true, kids: {}})
  end
  node[:kids][comps.last] = {dir: false, size: tk[0].to_i}
end
def size_of(n)
  n[:size] ||= n[:kids].values.sum { |k| size_of(k) }
end
def fmt(s)
  return "#{s}B" if s < 1024
  units = [["K", 1024], ["M", 1024**2], ["G", 1024**3]]
  idx = units.rindex { |_, u| u <= s }
  ch, u = units[idx]
  t = (s * 10 * 2 + u) / (2 * u)
  return "#{t / 10}.#{t % 10}#{ch}" if t < 100
  n = (2 * s + u) / (2 * u)
  return "1.0#{units[idx + 1][0]}" if n == 1024 && ch != "G"
  "#{n}#{ch}"
end
def line(size, d, name)
  format("%6s  %s%s", fmt(size), "  " * d, name)
end
size_of(root)
puts line(root[:size], 0, ".")
walk = nil
walk = ->(n, d) do
  return if d >= $depth
  ents = n[:kids].map { |name, k| [name, k] }.sort_by { |name, k| [-k[:size], name.b] }
  small = ents.select { |_, k| k[:size] < $thr }
  ents.each do |name, k|
    next if k[:size] < $thr
    puts line(k[:size], d + 1, k[:dir] ? "#{name}/" : name)
    walk.(k, d + 1) if k[:dir]
  end
  unless small.empty?
    puts line(small.sum { |_, k| k[:size] }, d + 1, "(#{small.size} smaller)")
  end
end
$depth = depth; $thr = thr
walk.(root, 0)

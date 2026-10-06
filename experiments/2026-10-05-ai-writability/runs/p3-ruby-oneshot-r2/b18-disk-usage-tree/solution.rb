lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
lines = lines.map { |l| l.chomp("\r") }
h = (lines[0] || "").split
unless h.size == 4 && h[0] == "depth" && h[2] == "threshold" && h[1] =~ /\A\d+\z/ && h[3] =~ /\A\d+\z/
  puts "bad header"
  exit
end
depth = h[1].to_i
thr = h[3].to_i
root = { name: ".", dir: true, kids: {}, size: 0 }
lines.each_with_index do |l, i|
  next if i == 0
  tk = l.split
  next if tk.empty?
  no = i + 1
  comps = nil
  if tk.size == 2 && tk[0] =~ /\A\d+\z/ && tk[0].to_i <= 10**13
    comps = tk[1].split("/", -1)
    comps = nil if comps.any? { |c| c.empty? || c == "." || c == ".." }
  end
  if comps.nil?
    puts "line #{no}: malformed"
    next
  end
  path = tk[1]
  size = tk[0].to_i
  node = root
  status = :ok
  comps.each_with_index do |c, j|
    kid = node[:kids][c]
    last = j == comps.size - 1
    if kid.nil?
      break
    elsif last
      status = kid[:dir] ? :conflict : :dup
    elsif !kid[:dir]
      status = :conflict
      break
    end
    node = kid
  end
  if status == :dup
    puts "line #{no}: duplicate #{path}"
    next
  elsif status == :conflict
    puts "line #{no}: conflict #{path}"
    next
  end
  node = root
  node[:size] += size
  comps.each_with_index do |c, j|
    last = j == comps.size - 1
    node = (node[:kids][c] ||= last ? { name: c, dir: false, size: size } : { name: c, dir: true, kids: {}, size: 0 })
    node[:size] += size if !last
  end
end

def fmt(s)
  return "#{s}B" if s < 1024
  units = [[1024**3, "G"], [1024**2, "M"], [1024, "K"]]
  idx = units.index { |u, _| u <= s }
  u, l = units[idx]
  t = (20 * s + u) / (2 * u)
  return "#{t / 10}.#{t % 10}#{l}" if t < 100
  n = (2 * s + u) / (2 * u)
  if n == 1024 && l != "G"
    return "1.0#{units[idx - 1][1]}"
  end
  "#{n}#{l}"
end

def line(size, d, name)
  format("%6s  %s%s", fmt(size), "  " * d, name)
end

def walk(node, d, depth, thr)
  return if d >= depth
  ents = node[:kids].values.sort_by { |k| [-k[:size], k[:name]] }
  small = 0
  smallsz = 0
  ents.each do |k|
    if k[:size] < thr
      small += 1
      smallsz += k[:size]
      next
    end
    puts line(k[:size], d + 1, k[:dir] ? "#{k[:name]}/" : k[:name])
    walk(k, d + 1, depth, thr) if k[:dir]
  end
  puts line(smallsz, d + 1, "(#{small} smaller)") if small > 0
end

puts line(root[:size], 0, ".")
walk(root, 0, depth, thr)

lines = STDIN.read.split("\n", -1)
lines.pop if lines.last == ""
h = lines[0] && lines[0].split
unless h && h.size == 4 && h[0] == "depth" && h[2] == "threshold" && h[1] =~ /\A\d+\z/ && h[3] =~ /\A\d+\z/
  puts "bad header"
  exit
end
maxd = h[1].to_i
thr = h[3].to_i

def fmt_size(s)
  return "#{s}B" if s < 1024
  units = [["K", 1024], ["M", 1024**2], ["G", 1024**3]]
  idx = units.rindex { |_, u| u <= s }
  letter, u = units[idx]
  t = (s * 20 + u) / (2 * u)
  return "#{t / 10}.#{t % 10}#{letter}" if t < 100
  n = (2 * s + u) / (2 * u)
  if n == 1024 && idx < 2
    return "1.0#{units[idx + 1][0]}"
  end
  "#{n}#{letter}"
end

root = { dir: true, kids: {}, size: 0 }
(1...lines.size).each do |i|
  l = lines[i]
  next if l.strip.empty?
  n = i + 1
  tk = l.split
  ok = tk.size == 2 && tk[0] =~ /\A\d+\z/ && tk[0].to_i <= 10**13
  comps = ok ? tk[1].split("/", -1) : nil
  ok &&= comps.none? { |c| c.empty? || c == "." || c == ".." }
  unless ok
    puts "line #{n}: malformed"
    next
  end
  path = tk[1]
  size = tk[0].to_i
  node = root
  status = nil
  comps.each_with_index do |c, j|
    last = j == comps.size - 1
    nx = node[:kids][c]
    if nx.nil?
      break
    elsif last
      status = nx[:dir] ? :conflict : :dup
    elsif !nx[:dir]
      status = :conflict
    end
    break if status
    node = nx
  end
  if status == :dup
    puts "line #{n}: duplicate #{path}"
    next
  elsif status == :conflict
    puts "line #{n}: conflict #{path}"
    next
  end
  node = root
  node[:size] += size
  comps.each_with_index do |c, j|
    last = j == comps.size - 1
    node[:kids][c] ||= last ? { dir: false, size: size } : { dir: true, kids: {}, size: 0 }
    node = node[:kids][c]
    node[:size] += size if !last
  end
end

def line(size, depth, name)
  format("%6s  %s%s", fmt_size(size), "  " * depth, name)
end

puts line(root[:size], 0, ".")
walk = lambda do |dir, depth|
  return if depth >= maxd
  ents = dir[:kids].sort_by { |name, e| [-e[:size], name.b] }
  small = ents.select { |_, e| e[:size] < thr }
  ents.each do |name, e|
    next if e[:size] < thr
    puts line(e[:size], depth + 1, e[:dir] ? "#{name}/" : name)
    walk.(e, depth + 1) if e[:dir]
  end
  unless small.empty?
    puts line(small.sum { |_, e| e[:size] }, depth + 1, "(#{small.size} smaller)")
  end
end
walk.(root, 0)

lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
h = (lines[0] || "").split
unless h.size == 4 && h[0] == "depth" && h[2] == "threshold" && h[1] =~ /\A\d+\z/ && h[3] =~ /\A\d+\z/
  puts "bad header"
  exit
end
depth = h[1].to_i
thr = h[3].to_i

# node: {dir: Hash} for directory, {size: Integer} for file
root = { dir: {} }
lines[1..].each_with_index do |ln, i|
  no = i + 2
  next if ln.strip.empty?
  tk = ln.split
  ok = tk.size == 2 && tk[0] =~ /\A\d+\z/ && tk[0].to_i <= 10**13
  comps = ok ? tk[1].split("/", -1) : nil
  ok &&= comps.none? { |c| c.empty? || c == "." || c == ".." }
  unless ok
    puts "line #{no}: malformed"
    next
  end
  path = tk[1]
  node = root
  status = nil
  comps.each_with_index do |c, j|
    last = j == comps.size - 1
    nx = node[:dir][c]
    if nx.nil?
      break
    elsif nx[:dir].nil?
      status = last ? :dup : :conflict
      break
    else
      if last
        status = :conflict
        break
      end
      node = nx
    end
  end
  if status == :dup
    puts "line #{no}: duplicate #{path}"
  elsif status == :conflict
    puts "line #{no}: conflict #{path}"
  else
    node = root
    comps[0..-2].each do |c|
      node = (node[:dir][c] ||= { dir: {} })
    end
    node[:dir][comps.last] = { size: tk[0].to_i }
  end
end

def total(n)
  n[:size] || (n[:total] ||= n[:dir].values.sum { |x| total(x) })
end

def fmt_size(s)
  return "#{s}B" if s < 1024
  units = [["K", 1024], ["M", 1024**2], ["G", 1024**3]]
  idx = units.rindex { |_, u| u <= s }
  letter, u = units[idx]
  t = (s * 10 + u / 2) / u
  return "#{t / 10}.#{t % 10}#{letter}" if t < 100
  n = (s + u / 2) / u
  if n == 1024 && idx < 2
    return "1.0#{units[idx + 1][0]}"
  end
  "#{n}#{letter}"
end

def line(size, ind, name)
  format("%6s  %s%s", fmt_size(size), "  " * ind, name)
end

def walk(n, d, depth, thr)
  return if d >= depth
  ents = n[:dir].map { |name, x| [name, x, total(x)] }
  ents.sort_by! { |name, _, sz| [-sz, name.b] }
  small = []
  ents.each do |name, x, sz|
    if sz < thr
      small << sz
      next
    end
    if x[:dir]
      puts line(sz, d + 1, name + "/")
      walk(x, d + 1, depth, thr)
    else
      puts line(sz, d + 1, name)
    end
  end
  puts line(small.sum, d + 1, "(#{small.size} smaller)") unless small.empty?
end

puts line(total(root), 0, ".")
walk(root, 0, depth, thr)

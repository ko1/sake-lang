class Node
  attr_reader :name, :children
  attr_accessor :size

  def initialize(name, size = 0, children = nil)
    @name = name
    @size = size
    @children = children # nil for a file, a Hash for a directory
  end

  def dir? = !children.nil?
  def label = dir? ? "#{name}/" : name
  def total = dir? ? children.values.sum(&:total) : size
end

UNITS = %w[B K M G].freeze

def round_div(a, b) = (2 * a + b) / (2 * b)

def human(s)
  k = 0
  k += 1 while k < 3 && s >= 1024**(k + 1)
  return "#{s}B" if k.zero?
  u = 1024**k
  tenths = round_div(s * 10, u)
  return "#{tenths / 10}.#{tenths % 10}#{UNITS[k]}" if tenths < 100
  n = round_div(s, u)
  return "1.0#{UNITS[k + 1]}" if n >= 1024 && k < 3
  "#{n}#{UNITS[k]}"
end

def show(size, depth, text)
  puts format("%6s  %s%s", human(size), "  " * depth, text)
end

def print_tree(node, depth, max_depth, threshold)
  show(node.total, depth, depth.zero? ? "." : node.label)
  return unless node.dir? && depth < max_depth
  kids = node.children.values.sort_by { |c| [-c.total, c.name] }
  big, small = kids.partition { |c| c.total > threshold }
  big.each { |c| print_tree(c, depth + 1, max_depth, threshold) }
  show(small.sum(&:total), depth + 1, "(#{small.size} smaller)") unless small.empty?
end

head = ($stdin.gets || "").split
unless head.size == 4 && head[0] == "depth" && head[2] == "threshold" && head.values_at(1, 3).all? { _1.match?(/\A\d+\z/) }
  puts "bad header"
  exit
end
max_depth = head[1].to_i
threshold = head[3].to_i

root = Node.new(".", 0, {})
$stdin.each_line.with_index(2) do |raw, no|
  toks = raw.split
  next if toks.empty?
  parts = toks[1]&.split("/", -1)
  if toks.size != 2 || !toks[0].match?(/\A\d+\z/) || parts.any? { |p| p.empty? || p == "." || p == ".." }
    puts "line #{no}: malformed"
    next
  end
  path = toks[1]
  dir = root
  conflict = false
  parts[0...-1].each do |p|
    child = dir.children[p]
    if child && !child.dir?
      conflict = true
      break
    end
    dir = (dir.children[p] ||= Node.new(p, 0, {}))
  end
  existing = conflict ? nil : dir.children[parts.last]
  if conflict || existing&.dir?
    puts "line #{no}: conflict #{path}"
  elsif existing
    puts "line #{no}: duplicate #{path}"
  else
    dir.children[parts.last] = Node.new(parts.last, toks[0].to_i)
  end
end

print_tree(root, 0, max_depth, threshold)

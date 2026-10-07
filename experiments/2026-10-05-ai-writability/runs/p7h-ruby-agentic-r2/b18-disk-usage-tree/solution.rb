#!/usr/bin/env ruby

K = 1024
M = 1024 * 1024
G = 1024 * 1024 * 1024

def format_size(size, k, m, g)
  if size < k
    "#{size}B"
  else
    if size >= g
      unit = g
      unit_char = 'G'
    elsif size >= m
      unit = m
      unit_char = 'M'
    else
      unit = k
      unit_char = 'K'
    end

    t = (size * 10.0 / unit).round

    if t < 100
      val = t / 10.0
      "#{val.round(1)}#{unit_char}"
    else
      n = (size.to_f / unit).round
      if n == 1024 && unit_char != 'G'
        return (unit_char == 'K' ? "1.0M" : "1.0G")
      else
        "#{n}#{unit_char}"
      end
    end
  end
end

# Parse header
header_line = gets.chomp
header_parts = header_line.split
if header_parts.size != 4 || header_parts[0] != "depth" || header_parts[2] != "threshold" ||
   !/^\d+$/.match?(header_parts[1]) || !/^\d+$/.match?(header_parts[3])
  puts "bad header"
  exit
end

max_depth = header_parts[1].to_i
threshold = header_parts[3].to_i

files = {}
errors = []
line_num = 1

while (line = gets)
  line_num += 1
  stripped = line.chomp
  next if stripped.match?(/^\s*$/)

  parts = stripped.split
  if parts.size != 2
    errors << "line #{line_num}: malformed"
    next
  end

  size_str, path = parts

  unless size_str.match?(/^\d+$/)
    errors << "line #{line_num}: malformed"
    next
  end

  size = size_str.to_i

  components = path.split('/')
  if components.any? { |c| c.empty? || c == '.' || c == '..' } || components.empty?
    errors << "line #{line_num}: malformed"
    next
  end

  if files.key?(path)
    errors << "line #{line_num}: duplicate #{path}"
    next
  end

  conflict = false
  files.each_key do |existing_path|
    if existing_path.start_with?(path + '/')
      errors << "line #{line_num}: conflict #{path}"
      conflict = true
      break
    end
  end
  next if conflict

  (1...components.size).each do |i|
    prefix = components[0...i].join('/')
    if files.key?(prefix)
      errors << "line #{line_num}: conflict #{path}"
      conflict = true
      break
    end
  end
  next if conflict

  files[path] = size
end

errors.each { |e| puts e }

class Node
  attr_accessor :name, :size, :children, :is_file, :depth

  def initialize(name, is_file = false)
    @name = name
    @is_file = is_file
    @size = 0
    @children = {}
    @depth = 0
  end

  def get_or_create_child(name, is_file = false)
    @children[name] ||= Node.new(name, is_file)
    @children[name].depth = @depth + 1
    @children[name]
  end

  def calculate_size
    if @is_file
      @size
    else
      @size = @children.values.sum { |c| c.calculate_size }
      @size
    end
  end
end

root = Node.new(".")
root.depth = 0

files.each do |path, size|
  components = path.split('/')
  current = root

  (0...components.size - 1).each do |i|
    current = current.get_or_create_child(components[i], false)
  end

  file_node = current.get_or_create_child(components[-1], true)
  file_node.size = size
end

root.calculate_size

def print_tree(node, max_depth, threshold, k, m, g)
  indent = "  " * node.depth
  size_str = format_size(node.size, k, m, g).rjust(6)
  name = node.is_file ? node.name : (node.name == "." ? "." : "#{node.name}/")

  puts "#{size_str}  #{indent}#{name}"

  if node.depth < max_depth && !node.is_file
    children = node.children.values.sort do |a, b|
      cmp = b.size <=> a.size
      cmp != 0 ? cmp : a.name <=> b.name
    end

    visible = children.select { |c| c.size >= threshold }
    hidden = children.select { |c| c.size < threshold }

    visible.each { |c| print_tree(c, max_depth, threshold, k, m, g) }

    if hidden.any?
      total_hidden = hidden.sum(&:size)
      indent_hidden = "  " * (node.depth + 1)
      size_str_hidden = format_size(total_hidden, k, m, g).rjust(6)
      puts "#{size_str_hidden}  #{indent_hidden}(#{hidden.size} smaller)"
    end
  end
end

print_tree(root, max_depth, threshold, K, M, G)

#!/usr/bin/env ruby

def format_size(size)
  if size < 1024
    return "#{size}B"
  end

  units = [1024, 1024**2, 1024**3]
  unit_chars = ['K', 'M', 'G']

  # Find largest unit
  u_index = 0
  u_index = 1 if size >= 1024**2
  u_index = 2 if size >= 1024**3

  u = units[u_index]

  t = (size * 10 / u).round

  if t < 100
    # Decimal format
    decimal = (size * 10 / u).round / 10.0
    return "#{decimal}#{unit_chars[u_index]}"
  else
    n = (size / u).round
    if n == 1024 && u_index < 2
      # Convert to next unit
      decimal = 1.0
      return "#{decimal}#{unit_chars[u_index + 1]}"
    else
      return "#{n}#{unit_chars[u_index]}"
    end
  end
end

# Parse header
header = gets.chomp
parts = header.split
if parts.length != 4 || parts[0] != "depth" || parts[2] != "threshold" || !parts[1].match?(/^\d+$/) || !parts[3].match?(/^\d+$/)
  puts "bad header"
  exit
end

depth_limit = parts[1].to_i
threshold = parts[3].to_i

# Parse files
files = {}  # path => size
errors = []
accepted_files = Set.new
all_paths = {}  # path => type (file/dir)

line_num = 1
while line = gets
  line_num += 1
  line = line.chomp
  next if line.strip.empty?

  parts = line.split
  if parts.length != 2
    errors << "line #{line_num}: malformed"
    next
  end

  size_str, path = parts

  if !size_str.match?(/^\d+$/)
    errors << "line #{line_num}: malformed"
    next
  end

  if !path.match?(%r{^[^/.][^/]*(?:/[^/.][^/]*)*$})
    errors << "line #{line_num}: malformed"
    next
  end

  size = size_str.to_i

  # Check for duplicate
  if accepted_files.include?(path)
    errors << "line #{line_num}: duplicate #{path}"
    next
  end

  # Check for conflicts
  conflict = false
  path.split("/").each_with_index do |component, idx|
    prefix_parts = path.split("/")[0..idx]
    prefix = prefix_parts.join("/")
    if idx < path.split("/").length - 1
      if accepted_files.include?(prefix)
        errors << "line #{line_num}: conflict #{path}"
        conflict = true
        break
      end
    end
  end

  next if conflict

  # Check if any prefix of this path is a file
  path_parts = path.split("/")
  (0...path_parts.length - 1).each do |i|
    potential_file = path_parts[0..i].join("/")
    if accepted_files.include?(potential_file)
      errors << "line #{line_num}: conflict #{path}"
      conflict = true
      break
    end
  end

  next if conflict

  accepted_files.add(path)
  files[path] = size
end

errors.each { |e| puts e }

if files.empty?
  exit
end

# Build tree
class Node
  attr_accessor :name, :is_file, :size, :children

  def initialize(name, is_file)
    @name = name
    @is_file = is_file
    @size = 0
    @children = {}
  end
end

root = Node.new(".", false)

# Populate tree
files.each do |path, size|
  parts = path.split("/")
  current = root

  parts.each_with_index do |part, idx|
    if idx == parts.length - 1
      # Create file
      current.children[part] = Node.new(part, true)
      current.children[part].size = size
    else
      # Create or navigate directory
      if !current.children[part]
        current.children[part] = Node.new(part, false)
      end
      current = current.children[part]
    end
  end
end

# Calculate sizes recursively
def calc_size(node)
  if node.is_file
    node.size
  else
    node.size = node.children.values.sum { |child| calc_size(child) }
  end
end

calc_size(root)

# Print tree
def print_tree(node, depth, depth_limit, threshold)
  # Print current node
  size_str = format_size(node.size)
  indent = "  " * depth

  if depth == 0
    name = "."
  elsif node.is_file
    name = node.name
  else
    name = node.name + "/"
  end

  printf "%6s  %s%s\n", size_str, indent, name

  # Print children if not at depth limit
  if depth < depth_limit && !node.is_file
    children = node.children.values.sort_by { |child| [-child.size, child.name] }

    printed = []
    smaller_count = 0
    smaller_size = 0

    children.each do |child|
      if child.size >= threshold
        printed << child
      else
        smaller_count += 1
        smaller_size += child.size
      end
    end

    printed.each do |child|
      print_tree(child, depth + 1, depth_limit, threshold)
    end

    if smaller_count > 0
      size_str = format_size(smaller_size)
      indent = "  " * (depth + 1)
      printf "%6s  %s(%d smaller)\n", size_str, indent, smaller_count
    end
  end
end

print_tree(root, 0, depth_limit, threshold)

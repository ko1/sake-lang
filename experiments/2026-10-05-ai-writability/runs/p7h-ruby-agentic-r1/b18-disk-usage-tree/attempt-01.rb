#!/usr/bin/env ruby

class Node
  attr_accessor :name, :size, :children, :is_file

  def initialize(name, is_file)
    @name = name
    @is_file = is_file
    @size = 0
    @children = {}
  end

  def total_size
    if @is_file
      @size
    else
      @children.values.sum { |c| c.total_size }
    end
  end
end

def format_size(size)
  return "#{size}B" if size < 1024

  units = { K: 1024, M: 1024**2, G: 1024**3 }
  unit_names = { K: "K", M: "M", G: "G" }

  # Find the largest unit not above size
  chosen_unit = nil
  chosen_unit_name = nil
  units.each do |name, value|
    if value <= size
      chosen_unit = value
      chosen_unit_name = name
    end
  end

  # Calculate t = size * 10 / unit rounded
  t = (size * 10.0 / chosen_unit).round

  if t < 100
    # Write as decimal: t/10 with one decimal place
    val = t / 10.0
    return "#{val}#{unit_names[chosen_unit_name]}"
  else
    # Round to nearest integer
    n = (size.to_f / chosen_unit).round

    if n == 1024 && chosen_unit != 1024**3
      # Switch to next unit
      next_unit = chosen_unit * 1024
      next_name_idx = units.keys.index(chosen_unit_name) + 1
      if next_name_idx < units.keys.size
        next_unit_name = units.keys[next_name_idx]
        return "1.0#{unit_names[next_unit_name]}"
      end
    end

    return "#{n}#{unit_names[chosen_unit_name]}"
  end
end

def main
  lines = STDIN.readlines.map(&:chomp)

  if lines.empty?
    puts "bad header"
    return
  end

  header_parts = lines[0].split
  if header_parts.size != 4 || header_parts[0] != "depth" || header_parts[2] != "threshold" ||
     !header_parts[1].match?(/^\d+$/) || !header_parts[3].match?(/^\d+$/)
    puts "bad header"
    return
  end

  depth_limit = header_parts[1].to_i
  threshold = header_parts[3].to_i

  # Build directory tree
  root = Node.new(".", false)
  accepted_files = Set.new
  accepted_dirs = Set.new
  accepted_dirs.add(".")

  errors = []

  lines[1..].each_with_index do |line, idx|
    line_num = idx + 2

    # Skip blank lines
    next if line.strip.empty?

    parts = line.split
    if parts.size != 2
      errors << "line #{line_num}: malformed"
      next
    end

    size_str, path = parts

    if !size_str.match?(/^\d+$/) || path.empty? || path.start_with?("/") || path.include?("/.") || path.include?("/..") || path.include?("//")
      errors << "line #{line_num}: malformed"
      next
    end

    # Check for duplicate
    if accepted_files.include?(path)
      errors << "line #{line_num}: duplicate #{path}"
      next
    end

    # Check for conflict (path is prefix of accepted file, or prefix is accepted file)
    conflict = false

    # Check if path is a prefix of any accepted file
    accepted_files.each do |file|
      if file.start_with?(path + "/")
        conflict = true
        break
      end
    end

    # Check if any prefix of path is an accepted file
    parts_path = path.split("/")
    (1...parts_path.size).each do |i|
      prefix = parts_path[0...i].join("/")
      if accepted_files.include?(prefix)
        conflict = true
        break
      end
    end

    if conflict
      errors << "line #{line_num}: conflict #{path}"
      next
    end

    # Accept the file
    size = size_str.to_i
    accepted_files.add(path)

    # Build directory tree
    parts_path = path.split("/")
    current = root

    # Create parent directories
    (0...parts_path.size - 1).each do |i|
      dir_name = parts_path[i]
      if !current.children.key?(dir_name)
        current.children[dir_name] = Node.new(dir_name, false)
        accepted_dirs.add((parts_path[0..i].join("/")))
      end
      current = current.children[dir_name]
    end

    # Add file
    file_name = parts_path[-1]
    current.children[file_name] = Node.new(file_name, true)
    current.children[file_name].size = size
  end

  # Print errors
  errors.each { |err| puts err }

  # Print tree
  def print_tree(node, depth, depth_limit, threshold, prefix = "")
    entries = []
    small_entries = []

    node.children.values.each do |child|
      total = child.total_size
      if total < threshold
        small_entries.push(child)
      else
        entries.push(child)
      end
    end

    # Sort: by size descending, then name ascending
    entries.sort! do |a, b|
      if a.total_size != b.total_size
        b.total_size <=> a.total_size
      else
        a.name <=> b.name
      end
    end

    indent = "  " * depth

    # Print entries
    entries.each do |child|
      size_str = format_size(child.total_size)
      if child.is_file
        puts "#{size_str.rjust(6)}  #{indent}#{child.name}"
      else
        puts "#{size_str.rjust(6)}  #{indent}#{child.name}/"
      end

      if !child.is_file && depth + 1 < depth_limit
        print_tree(child, depth + 1, depth_limit, threshold, prefix + "  ")
      end
    end

    # Print small entries summary
    if !small_entries.empty?
      small_total = small_entries.sum { |e| e.total_size }
      size_str = format_size(small_total)
      puts "#{size_str.rjust(6)}  #{indent}(#{small_entries.size} smaller)"
    end
  end

  # Print root
  size_str = format_size(root.total_size)
  puts "#{size_str.rjust(6)}  ."

  # Print tree starting from depth 1
  if depth_limit > 1
    print_tree(root, 1, depth_limit, threshold)
  end
end

main

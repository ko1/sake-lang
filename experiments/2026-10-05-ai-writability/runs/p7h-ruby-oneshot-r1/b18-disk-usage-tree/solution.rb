#!/usr/bin/env ruby

def format_size(bytes)
  if bytes < 1024
    "#{bytes}B"
  else
    units = { 1024 => 'K', 1024**2 => 'M', 1024**3 => 'G' }
    unit = 1024
    unit = 1024**2 if bytes >= 1024**2
    unit = 1024**3 if bytes >= 1024**3

    t = (bytes * 10 / unit + 0.5).to_i
    if t < 100
      "#{t / 10.0}#{units[unit]}"
    else
      n = (bytes.to_f / unit + 0.5).to_i
      if n == 1024 && unit < 1024**3
        next_unit = unit * 1024
        "1.0#{units[next_unit]}"
      else
        "#{n}#{units[unit]}"
      end
    end
  end
end

# Parse header
header = gets.strip
parts = header.split
unless parts.size == 4 && parts[0] == "depth" && parts[2] == "threshold" &&
       /^\d+$/ === parts[1] && /^\d+$/ === parts[3]
  puts "bad header"
  exit
end

max_depth = parts[1].to_i
threshold = parts[3].to_i

# Build tree
files = {}  # path => size
dirs = Set.new(["."])
errors = []

STDIN.each_line.with_index do |line, idx|
  line_num = idx + 2
  line = line.rstrip

  next if line.empty?

  parts = line.split(/\s+/)
  unless parts.size == 2 && /^\d+$/ === parts[0] && !parts[1].empty?
    errors << "line #{line_num}: malformed"
    next
  end

  size_str = parts[0]
  path = parts[1]

  # Check for invalid path
  if path.start_with?('/') || path.include?('..') || path.include?('/.') || path.include?('/..')
    errors << "line #{line_num}: malformed"
    next
  end

  size = size_str.to_i

  # Check if path equals earlier accepted file
  if files[path]
    errors << "line #{line_num}: duplicate #{path}"
    next
  end

  # Check for conflicts
  conflict = false
  files.each_key do |file_path|
    # Check if file_path is prefix of path
    if path.start_with?(file_path + "/")
      errors << "line #{line_num}: conflict #{path}"
      conflict = true
      break
    end
    # Check if path is prefix of file_path
    if file_path.start_with?(path + "/")
      errors << "line #{line_num}: conflict #{path}"
      conflict = true
      break
    end
  end

  next if conflict

  # Add file and its parent directories
  files[path] = size

  # Create parent directories
  parts = path.split('/')
  (0...parts.size).each do |i|
    dir = parts[0..i].join('/')
    dirs << dir if i < parts.size - 1 || path.include?('/')
  end

  # Actually, let me rethink this. Let me build dirs properly.
  current = "."
  parts[0...-1].each do |part|
    current = "#{current}/#{part}"
    dirs << current
  end
end

errors.each { |msg| puts msg }

# Calculate directory sizes
def calc_size(path, files, dirs)
  if path == "."
    files.sum { |f, sz| f.start_with?(".") || f.count('/').zero? ? sz : (f.split('/')[0] == "." || f[0] != "/" ? sz : 0) }
  else
    files.sum do |f, sz|
      if f == path
        sz
      elsif f.start_with?(path + "/")
        sz
      else
        0
      end
    end
  end
end

def get_children(path, files, dirs)
  if path == "."
    children = Set.new
    files.each_key do |f|
      parts = f.split('/')
      children << parts[0] if parts.size == 1 && !f.include?('/')
    end
    dirs.each do |d|
      parts = d.split('/')
      children << parts[0] if parts.size == 1 && !d.include?('/')
    end
  else
    children = Set.new
    prefix = path + "/"
    files.each_key do |f|
      if f.start_with?(prefix)
        rest = f[prefix.size..-1]
        child = rest.split('/')[0]
        children << child
      end
    end
    dirs.each do |d|
      if d.start_with?(prefix)
        rest = d[prefix.size..-1]
        child = rest.split('/')[0]
        children << child if rest.include?('/')
      end
    end
  end
  children.sort
end

def print_tree(path, depth, max_depth, threshold, files, dirs)
  return if depth > max_depth

  size = calc_size(path, files, dirs)
  indent = "  " * depth

  if path == "."
    printf("%6s  %s\n", format_size(size), path)
  else
    name = path.split('/').last
    is_dir = dirs.include?(path)
    if is_dir
      printf("%6s  %s%s/\n", format_size(size), indent, name)
    else
      printf("%6s  %s%s\n", format_size(size), indent, name)
    end
  end

  return if depth >= max_depth

  children = get_children(path, files, dirs)

  # Separate into shown and hidden
  shown = []
  hidden_size = 0
  hidden_count = 0

  children.each do |child|
    if path == "."
      child_path = child
    else
      child_path = "#{path}/#{child}"
    end

    child_size = calc_size(child_path, files, dirs)

    if child_size >= threshold
      shown << [child_path, child_size]
    else
      hidden_size += child_size
      hidden_count += 1
    end
  end

  # Sort shown children
  shown.sort! { |a, b| a[1] == b[1] ? a[0] <=> b[0] : b[1] <=> a[1] }

  shown.each do |child_path, child_size|
    print_tree(child_path, depth + 1, max_depth, threshold, files, dirs)
  end

  if hidden_count > 0
    hidden_indent = "  " * (depth + 1)
    printf("%6s  %s(%d smaller)\n", format_size(hidden_size), hidden_indent, hidden_count)
  end
end

print_tree(".", 0, max_depth, threshold, files, dirs)

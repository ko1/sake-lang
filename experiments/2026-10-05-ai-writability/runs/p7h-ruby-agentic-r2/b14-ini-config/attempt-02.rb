#!/usr/bin/env ruby

# Read all input
all_lines = STDIN.readlines.map { |line| line.rstrip }

# Find %% separator
config_end = nil
all_lines.each_with_index do |line, idx|
  if line.strip == "%%"
    config_end = idx
    break
  end
end

# Split into config and queries
config_lines = config_end ? all_lines[0...config_end] : all_lines
query_lines = config_end ? all_lines[(config_end + 1)..-1] || [] : []

# Parse configuration
config = {}  # {section => {key => value}}
current_section = "main"
sections = Set.new
sections.add("main")

config_lines.each_with_index do |line, idx|
  line_num = idx + 1
  line = line.strip

  # Skip empty lines and comments
  if line.empty? || line.start_with?("#") || line.start_with?(";")
    next
  end

  # Check for section header
  if line.start_with?("[") && line.end_with?("]")
    section_name = line[1..-2]
    if section_name.match?(/^[a-z0-9_]+$/)
      current_section = section_name
      sections.add(section_name)
      config[current_section] ||= {}
      next
    else
      puts "line #{line_num}: syntax error"
      next
    end
  end

  # Check for KEY = VALUE
  if line.include?("=")
    eq_idx = line.index("=")
    key = line[0...eq_idx].strip
    value = line[(eq_idx + 1)..-1].strip

    if key.match?(/^[a-z0-9_]+$/)
      config[current_section] ||= {}
      if config[current_section].key?(key)
        puts "line #{line_num}: duplicate key #{current_section}.#{key}"
      end
      config[current_section][key] = value
    else
      puts "line #{line_num}: syntax error"
    end
  else
    # Syntax error
    puts "line #{line_num}: syntax error"
  end
end

# Resolve values with cycle detection
def resolve_value(config, section, key, resolving_path = Set.new)
  full_key = "#{section}.#{key}"

  if resolving_path.include?(full_key)
    # Cycle detected
    cycle_list = resolving_path.to_a + [full_key]
    cycle_str = cycle_list.join(" -> ")
    return { error: "cycle #{cycle_str}" }
  end

  if !config.key?(section) || !config[section].key?(key)
    return { error: "undefined #{full_key}" }
  end

  value = config[section][key]
  new_path = resolving_path.dup
  new_path.add(full_key)

  # Replace references
  result = ""
  i = 0
  while i < value.length
    if value[i..i+1] == "${"
      # Find closing }
      close_idx = value.index("}", i + 2)
      if close_idx
        ref = value[(i + 2)...close_idx]

        # Parse reference: SECTION.KEY or KEY
        if ref.include?(".")
          ref_section, ref_key = ref.split(".", 2)
        else
          ref_section = section
          ref_key = ref
        end

        # Resolve reference
        if ref_section.match?(/^[a-z0-9_]+$/) && ref_key.match?(/^[a-z0-9_]+$/)
          resolved = resolve_value(config, ref_section, ref_key, new_path)
          if resolved.key?(:error)
            return resolved
          else
            result += resolved[:value]
          end
          i = close_idx + 1
        else
          # Malformed reference, treat as literal
          result += value[i..close_idx]
          i = close_idx + 1
        end
      else
        # No closing }, treat as literal
        result += value[i..-1]
        break
      end
    else
      result += value[i]
      i += 1
    end
  end

  { value: result }
end

def get_typed_value(value)
  # Determine type
  if value.match?(/^[+-]?\d+$/)
    # Integer
    int_val = value.to_i
    "int #{int_val}"
  elsif value.downcase == "true" || value.downcase == "yes" || value.downcase == "on"
    "bool true"
  elsif value.downcase == "false" || value.downcase == "no" || value.downcase == "off"
    "bool false"
  elsif value.include?(",")
    # List
    items = value.split(",").map(&:strip).reject(&:empty?)
    if items.empty?
      "list[0]"
    else
      "list[#{items.length}] #{items.join(" | ")}"
    end
  else
    # String
    "str \"#{value}\""
  end
end

# Process queries
query_lines.each_with_index do |line, idx|
  line_num = (config_lines.length + 1) + idx + 1  # Adjust for %% line and config lines
  line = line.strip

  # Skip empty lines
  if line.empty?
    next
  end

  words = line.split

  if words.empty?
    next
  end

  case words[0]
  when "GET"
    if words.length != 2
      puts "line #{line_num}: bad query"
      next
    end

    name = words[1]
    if name.include?(".")
      section, key = name.split(".", 2)
      full_name = name
    else
      section = "main"
      key = name
      full_name = "main.#{key}"
    end

    if !config.key?(section) || !config[section].key?(key)
      puts "#{full_name}: not found"
      next
    end

    resolved = resolve_value(config, section, key)
    if resolved.key?(:error)
      puts "#{full_name}: error: #{resolved[:error]}"
    else
      typed = get_typed_value(resolved[:value])
      puts "#{full_name} = #{typed}"
    end

  when "KEYS"
    if words.length != 2
      puts "line #{line_num}: bad query"
      next
    end

    section = words[1]
    if !sections.include?(section)
      puts "#{section}: not found"
      next
    end

    if !config.key?(section) || config[section].empty?
      puts "#{section}: (none)"
    else
      keys = config[section].keys.sort
      puts "#{section}: #{keys.join(", ")}"
    end

  else
    puts "line #{line_num}: bad query"
  end
end

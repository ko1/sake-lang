#!/usr/bin/env ruby

config = {}  # section -> key -> value
sections_order = []
line_num = 0

# Parse configuration
STDIN.each_line do |line|
  line_num += 1
  trimmed = line.strip

  if trimmed == "%%"
    break
  end

  next if trimmed.empty? || trimmed.start_with?('#') || trimmed.start_with?(';')

  if trimmed.start_with?('[') && trimmed.end_with?(']')
    section_name = trimmed[1..-2]
    if section_name =~ /^[a-z0-9_]+$/
      if !config[section_name]
        sections_order << section_name
        config[section_name] = {}
      end
    else
      puts "line #{line_num}: syntax error"
    end
  elsif trimmed.include?('=')
    idx = trimmed.index('=')
    key = trimmed[0...idx].strip
    value = trimmed[idx+1..-1].strip

    if key !~ /^[a-z0-9_]+$/
      puts "line #{line_num}: syntax error"
    else
      # Determine current section
      current_section = sections_order.last || "main"
      if !config[current_section]
        sections_order << current_section
        config[current_section] = {}
      end

      if config[current_section][key]
        puts "line #{line_num}: duplicate key #{current_section}.#{key}"
      else
        config[current_section][key] = value
      end
    end
  else
    puts "line #{line_num}: syntax error"
  end
end

# Resolve references
def resolve_value(section, key, config, visiting = Set.new)
  if !config[section]
    return nil, "undefined #{section}.#{key}"
  end

  if !config[section][key]
    return nil, "undefined #{section}.#{key}"
  end

  full_key = "#{section}.#{key}"
  if visiting.include?(full_key)
    cycle = visiting.to_a + [full_key]
    return nil, "cycle " + cycle.join(" -> ")
  end

  value = config[section][key]
  visiting_copy = visiting.dup
  visiting_copy.add(full_key)

  result = ""
  i = 0
  while i < value.length
    if value[i..i+1] == "${"
      # Find closing }
      close_idx = value.index("}", i+2)
      if !close_idx
        result += value[i..-1]
        break
      end

      ref = value[i+2...close_idx]

      if ref =~ /^[a-z0-9_]+$/ && !ref.include?('.')
        # Reference to same section
        ref_section = section
        ref_key = ref
      elsif ref =~ /^[a-z0-9_]+\.[a-z0-9_]+$/
        # Reference to other section
        parts = ref.split('.')
        ref_section = parts[0]
        ref_key = parts[1]
      else
        # Malformed reference
        result += value[i..close_idx]
        i = close_idx + 1
        next
      end

      resolved, error = resolve_value(ref_section, ref_key, config, visiting_copy)
      if error
        return nil, error
      end

      result += resolved
      i = close_idx + 1
    else
      result += value[i]
      i += 1
    end
  end

  return result, nil
end

# Format value
def format_value(text)
  # Check if int
  if text =~ /^[+-]?\d+$/
    int_val = text.to_i
    return "int #{int_val}"
  end

  # Check if bool
  if text =~ /^(true|yes|on)$/i
    return "bool true"
  elsif text =~ /^(false|no|off)$/i
    return "bool false"
  end

  # Check if list
  if text.include?(',')
    items = text.split(',').map(&:strip).reject(&:empty?)
    if items.empty?
      return "list[0]"
    else
      return "list[#{items.length}] " + items.join(" | ")
    end
  end

  # String
  return "str \"#{text}\""
end

# Process queries
STDIN.each_line do |line|
  line_num += 1
  trimmed = line.strip
  next if trimmed.empty?

  parts = trimmed.split

  if parts.length == 2 && parts[0] == "GET"
    name = parts[1]
    if name.include?('.')
      section, key = name.split('.', 2)
    else
      section = "main"
      key = name
    end

    if !config[section] || !config[section][key]
      puts "#{section}.#{key}: not found"
    else
      resolved, error = resolve_value(section, key, config)
      if error
        puts "#{section}.#{key}: error: #{error}"
      else
        formatted = format_value(resolved)
        puts "#{section}.#{key} = #{formatted}"
      end
    end
  elsif parts.length == 2 && parts[0] == "KEYS"
    section = parts[1]
    if !config[section]
      puts "#{section}: not found"
    else
      keys = config[section].keys.sort
      if keys.empty?
        puts "#{section}: (none)"
      else
        puts "#{section}: " + keys.join(", ")
      end
    end
  else
    puts "line #{line_num}: bad query"
  end
end

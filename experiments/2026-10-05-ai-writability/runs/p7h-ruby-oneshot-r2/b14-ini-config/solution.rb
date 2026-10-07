config = {}
current_section = "main"
config["main"] = {}
line_num = 1

# Parse configuration
while true
  line = STDIN.readline.chomp
  line = line.strip

  break if line == "%%"

  next if line.empty? || line.start_with?("#") || line.start_with?(";")

  if line.start_with?("[") && line.end_with?("]")
    section_name = line[1..-2]
    if section_name !~ /^[a-z0-9_]+$/i
      puts "line #{line_num}: syntax error"
      line_num += 1
      next
    end
    current_section = section_name
    config[current_section] ||= {}
    line_num += 1
    next
  end

  if line.include?("=")
    parts = line.split("=", 2)
    key = parts[0].strip
    value = parts[1].strip

    if key !~ /^[a-z0-9_]+$/i
      puts "line #{line_num}: syntax error"
      line_num += 1
      next
    end

    if config[current_section].key?(key)
      puts "line #{line_num}: duplicate key #{current_section}.#{key}"
    end

    config[current_section][key] = value
  else
    puts "line #{line_num}: syntax error"
  end

  line_num += 1
end

line_num += 1

# Helper function to resolve references
def resolve_value(section, key, config, visiting = Set.new)
  full_key = "#{section}.#{key}"

  if visiting.include?(full_key)
    cycle_path = visiting.to_a.join(" -> ") + " -> #{full_key}"
    return { error: "cycle #{cycle_path}" }
  end

  if !config[section] || !config[section][key]
    return { error: "undefined #{full_key}" }
  end

  value = config[section][key]
  visiting_copy = visiting.dup
  visiting_copy.add(full_key)

  result = ""
  i = 0
  while i < value.length
    if value[i..i+1] == "${"
      # Find the closing }
      j = value.index("}", i + 2)
      if j.nil?
        result << value[i..-1]
        break
      end

      ref = value[i+2...j]

      if ref.include?(".")
        ref_parts = ref.split(".", 2)
        ref_section = ref_parts[0]
        ref_key = ref_parts[1]
      else
        ref_section = section
        ref_key = ref
      end

      if ref_section !~ /^[a-z0-9_]+$/i || ref_key !~ /^[a-z0-9_]+$/i
        result << value[i...j+1]
        i = j + 1
        next
      end

      ref_value = resolve_value(ref_section, ref_key, config, visiting_copy)
      if ref_value.key?(:error)
        return ref_value
      end

      result << ref_value[:value]
      i = j + 1
    else
      result << value[i]
      i += 1
    end
  end

  { value: result }
end

# Helper function to format values
def format_value(value)
  # Check if it's an integer
  if value =~ /^[+-]?\d+$/
    int_val = value.to_i
    return "int #{int_val}"
  end

  # Check if it's a boolean
  if value.downcase == "true" || value.downcase == "yes" || value.downcase == "on"
    return "bool true"
  end

  if value.downcase == "false" || value.downcase == "no" || value.downcase == "off"
    return "bool false"
  end

  # Check if it contains a comma (list)
  if value.include?(",")
    items = value.split(",").map(&:strip).reject(&:empty?)
    if items.empty?
      return "list[0]"
    else
      return "list[#{items.length}] #{items.join(" | ")}"
    end
  end

  # Otherwise it's a string
  "str \"#{value}\""
end

# Process queries
while true
  line = begin
    STDIN.readline.chomp
  rescue EOFError
    break
  end

  line = line.strip
  next if line.empty?

  words = line.split

  if words.empty?
    line_num += 1
    next
  end

  command = words[0]

  if command == "GET"
    if words.length != 2
      puts "line #{line_num}: bad query"
      line_num += 1
      next
    end

    key_spec = words[1]
    if key_spec.include?(".")
      parts = key_spec.split(".", 2)
      section = parts[0]
      key = parts[1]
    else
      section = "main"
      key = key_spec
    end

    if !config[section] || !config[section][key]
      puts "#{section}.#{key}: not found"
      line_num += 1
      next
    end

    resolved = resolve_value(section, key, config)
    if resolved.key?(:error)
      puts "#{section}.#{key}: error: #{resolved[:error]}"
    else
      formatted = format_value(resolved[:value])
      puts "#{section}.#{key} = #{formatted}"
    end
  elsif command == "KEYS"
    if words.length != 2
      puts "line #{line_num}: bad query"
      line_num += 1
      next
    end

    section = words[1]

    if !config[section] || config[section].empty?
      puts "#{section}: not found"
      line_num += 1
      next
    end

    keys = config[section].keys.sort
    puts "#{section}: #{keys.join(", ")}"
  else
    puts "line #{line_num}: bad query"
  end

  line_num += 1
end

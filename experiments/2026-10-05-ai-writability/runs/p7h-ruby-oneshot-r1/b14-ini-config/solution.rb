config = {}
current_section = 'main'
config[current_section] = {}
line_num = 0

while true
  line_num += 1
  line = STDIN.readline.chomp
  line = line.strip

  if line == '%%'
    break
  end

  if line.empty? || line.start_with?('#') || line.start_with?(';')
    next
  end

  if line.start_with?('[') && line.end_with?(']')
    section_name = line[1..-2]
    if section_name =~ /^[a-z0-9_]*$/ && section_name.length > 0
      current_section = section_name
      config[current_section] ||= {}
    else
      puts "line #{line_num}: syntax error"
    end
  elsif line.include?('=')
    idx = line.index('=')
    key = line[0...idx].strip
    value = line[idx+1..-1].strip

    if key =~ /^[a-z0-9_]+$/
      config[current_section] ||= {}
      if config[current_section][key]
        puts "line #{line_num}: duplicate key #{current_section}.#{key}"
      end
      config[current_section][key] = value
    else
      puts "line #{line_num}: syntax error"
    end
  else
    puts "line #{line_num}: syntax error"
  end
end

def resolve_value(config, section, key, path = [])
  full_key = "#{section}.#{key}"

  if path.include?(full_key)
    cycle = path[path.index(full_key)..-1] + [full_key]
    return [:cycle, cycle.join(' -> ')]
  end

  if !config[section] || !config[section][key]
    return [:undefined, full_key]
  end

  value = config[section][key]
  new_path = path + [full_key]

  result = ""
  i = 0
  while i < value.length
    if i + 1 < value.length && value[i..i+1] == '${'
      end_idx = value.index('}', i + 2)
      if end_idx.nil?
        result += value[i..]
        break
      else
        ref = value[i+2...end_idx]
        if ref.include?('.')
          parts = ref.split('.', 2)
          ref_section = parts[0]
          ref_key = parts[1]
        else
          ref_section = section
          ref_key = ref
        end

        if ref =~ /^[a-z0-9_]+(\.[a-z0-9_]+)?$/ && ref_key && ref_key.length > 0
          resolved = resolve_value(config, ref_section, ref_key, new_path)
          if resolved[0] == :cycle || resolved[0] == :undefined
            return resolved
          else
            result += resolved[1]
            i = end_idx + 1
          end
        else
          result += value[i..end_idx]
          i = end_idx + 1
        end
      end
    else
      result += value[i]
      i += 1
    end
  end

  [:ok, result]
end

def format_value(value)
  if value =~ /^[+-]?\d+$/
    "int #{value.to_i}"
  elsif value.downcase == 'true' || value.downcase == 'yes' || value.downcase == 'on'
    "bool true"
  elsif value.downcase == 'false' || value.downcase == 'no' || value.downcase == 'off'
    "bool false"
  elsif value.include?(',')
    items = value.split(',').map(&:strip).reject(&:empty?)
    if items.length > 0
      "list[#{items.length}] #{items.join(' | ')}"
    else
      "list[0]"
    end
  else
    "str \"#{value}\""
  end
end

while true
  line_num += 1
  begin
    line = STDIN.readline.chomp
  rescue EOFError
    break
  end

  line = line.strip
  if line.empty?
    next
  end

  parts = line.split

  if parts.length == 0
    next
  elsif parts[0] == 'GET' && parts.length == 2
    query = parts[1]
    if query.include?('.')
      query_parts = query.split('.', 2)
      section = query_parts[0]
      key = query_parts[1]
    else
      section = 'main'
      key = query
    end

    if !config[section] || !config[section][key]
      puts "#{query}: not found"
    else
      resolved = resolve_value(config, section, key)
      if resolved[0] == :cycle
        puts "#{query}: error: #{resolved[1]}"
      elsif resolved[0] == :undefined
        puts "#{query}: error: undefined #{resolved[1]}"
      else
        puts "#{query} = #{format_value(resolved[1])}"
      end
    end
  elsif parts[0] == 'KEYS' && parts.length == 2
    section = parts[1]
    if config[section]
      keys = config[section].keys.sort
      puts "#{section}: #{keys.join(', ')}"
    else
      puts "#{section}: not found"
    end
  else
    puts "line #{line_num}: bad query"
  end
end

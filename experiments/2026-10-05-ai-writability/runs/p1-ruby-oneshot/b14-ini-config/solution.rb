NAME = /\A[a-z0-9_]+\z/
sections = {}
out = []
in_queries = false
section = "main"
lines = $stdin.each_line.map { |l| l.chomp }

def resolve(sections, sec, key, stack)
  id = "#{sec}.#{key}"
  stack.push(id)
  value = sections[sec][key]
  result = +""
  pos = 0
  while (m = /\$\{([a-z0-9_]+(?:\.[a-z0-9_]+)?)\}/.match(value, pos))
    result << value[pos...m.begin(0)]
    name = m[1]
    tsec, tkey = name.include?(".") ? name.split(".", 2) : [sec, name]
    tid = "#{tsec}.#{tkey}"
    unless sections[tsec] && sections[tsec].key?(tkey)
      stack.pop
      return [nil, "undefined #{tid}"]
    end
    if stack.include?(tid)
      r = stack.dup
      stack.pop
      return [nil, "cycle #{(r + [tid]).join(" -> ")}"]
    end
    text, err = resolve(sections, tsec, tkey, stack)
    if err
      stack.pop
      return [nil, err]
    end
    result << text
    pos = m.end(0)
  end
  result << value[pos..]
  stack.pop
  [result, nil]
end

def typed(v)
  if v =~ /\A[+-]?\d+\z/
    "int #{v.to_i}"
  elsif v =~ /\A(true|yes|on)\z/i
    "bool true"
  elsif v =~ /\A(false|no|off)\z/i
    "bool false"
  elsif v.include?(",")
    items = v.split(",", -1).map(&:strip).reject(&:empty?)
    items.empty? ? "list[0]" : "list[#{items.size}] #{items.join(" | ")}"
  else
    "str \"#{v}\""
  end
end

lines.each_with_index do |raw, i|
  n = i + 1
  line = raw.strip
  if !in_queries
    if line == "%%"
      in_queries = true
    elsif line.empty? || line.start_with?("#") || line.start_with?(";")
      next
    elsif (m = /\A\[([a-z0-9_]+)\]\z/.match(line))
      section = m[1]
      sections[section] ||= {}
    elsif (idx = line.index("=")) && line[0, idx].strip =~ NAME
      key = line[0, idx].strip
      val = line[(idx + 1)..].strip
      sections[section] ||= {}
      out << "line #{n}: duplicate key #{section}.#{key}" if sections[section].key?(key)
      sections[section][key] = val
    else
      out << "line #{n}: syntax error"
    end
  else
    next if line.empty?
    w = line.split(/ +/)
    if w.size == 2 && w[0] == "GET" && w[1] =~ /\A[a-z0-9_]+(\.[a-z0-9_]+)?\z/
      sec, key = w[1].include?(".") ? w[1].split(".", 2) : ["main", w[1]]
      if !(sections[sec] && sections[sec].key?(key))
        out << "#{sec}.#{key}: not found"
      else
        v, err = resolve(sections, sec, key, [])
        out << (err ? "#{sec}.#{key}: error: #{err}" : "#{sec}.#{key} = #{typed(v)}")
      end
    elsif w.size == 2 && w[0] == "KEYS" && w[1] =~ NAME
      if sections[w[1]]
        ks = sections[w[1]].keys.sort
        out << "#{w[1]}: #{ks.empty? ? "(none)" : ks.join(", ")}"
      else
        out << "#{w[1]}: not found"
      end
    else
      out << "line #{n}: bad query"
    end
  end
end
puts out

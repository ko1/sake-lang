lines = $stdin.read.split("\n", -1).map { |l| l.chomp("\r") }
lines.pop if lines.last == ""
NAME = /\A[a-z0-9_]+\z/
sections = {}
out = []
cur = "main"
idx = 0
while idx < lines.size
  n = idx + 1
  line = lines[idx].strip
  idx += 1
  break if line == "%%"
  next if line.empty? || line.start_with?("#") || line.start_with?(";")
  if (md = /\A\[([a-z0-9_]+)\]\z/.match(line))
    cur = md[1]
    sections[cur] ||= {}
  elsif line.include?("=")
    k, v = line.split("=", 2)
    k = k.strip
    v = v.strip
    if k =~ NAME
      sections[cur] ||= {}
      out << "line #{n}: duplicate key #{cur}.#{k}" if sections[cur].key?(k)
      sections[cur][k] = v
    else
      out << "line #{n}: syntax error"
    end
  else
    out << "line #{n}: syntax error"
  end
end

$memo = {}
REF = /\$\{([a-z0-9_]+(?:\.[a-z0-9_]+)?)\}/

# returns [:ok, text] or [:err, message]
resolve = nil
resolve = lambda do |sec, key, stack|
  id = "#{sec}.#{key}"
  return [:ok, $memo[id]] if $memo.key?(id)
  stack2 = stack + [id]
  value = sections[sec][key]
  res = +""
  pos = 0
  while (m = REF.match(value, pos))
    res << value[pos...m.begin(0)]
    ref = m[1]
    rs, rk = ref.include?(".") ? ref.split(".", 2) : [sec, ref]
    rid = "#{rs}.#{rk}"
    if stack2.include?(rid)
      return [:err, "cycle " + (stack2 + [rid]).join(" -> ")]
    end
    unless sections[rs] && sections[rs].key?(rk)
      return [:err, "undefined #{rid}"]
    end
    r = resolve.call(rs, rk, stack2)
    return r if r[0] == :err
    res << r[1]
    pos = m.end(0)
  end
  res << value[pos..]
  $memo[id] = res
  [:ok, res]
end

typed = lambda do |v|
  if v =~ /\A[+-]?\d+\z/
    "int #{v.to_i}"
  elsif %w[true yes on].include?(v.downcase)
    "bool true"
  elsif %w[false no off].include?(v.downcase)
    "bool false"
  elsif v.include?(",")
    items = v.split(",", -1).map(&:strip).reject(&:empty?)
    items.empty? ? "list[0]" : "list[#{items.size}] #{items.join(' | ')}"
  else
    "str \"#{v}\""
  end
end

while idx < lines.size
  n = idx + 1
  line = lines[idx].strip
  idx += 1
  next if line.empty?
  w = line.split(/ +/)
  if w[0] == "GET" && w.size == 2
    name = w[1]
    sec, key = name.include?(".") ? name.split(".", 2) : ["main", name]
    id = "#{sec}.#{key}"
    if sections[sec] && sections[sec].key?(key)
      r = resolve.call(sec, key, [])
      if r[0] == :ok
        out << "#{id} = #{typed.call(r[1])}"
      else
        out << "#{id}: error: #{r[1]}"
      end
    else
      out << "#{id}: not found"
    end
  elsif w[0] == "KEYS" && w.size == 2
    s = w[1]
    if sections[s]
      ks = sections[s].keys.sort
      out << "#{s}: #{ks.empty? ? '(none)' : ks.join(', ')}"
    else
      out << "#{s}: not found"
    end
  else
    out << "line #{n}: bad query"
  end
end
puts out

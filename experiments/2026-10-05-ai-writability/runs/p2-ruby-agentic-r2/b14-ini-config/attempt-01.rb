NAME = /\A[a-z0-9_]+\z/
REF = /\$\{([a-z0-9_]+)(?:\.([a-z0-9_]+))?\}/

lines = $stdin.each_line.map { |l| l.strip }
sections = {}
cur = "main"
out = []
idx = 0
while idx < lines.size
  l = lines[idx]
  idx += 1
  n = idx
  break if l == "%%"
  next if l.empty? || l.start_with?("#") || l.start_with?(";")
  if l =~ /\A\[([^\]]*)\]\z/ && $1 =~ NAME
    cur = $1
    sections[cur] ||= {}
  elsif (i = l.index("="))
    key = l[0, i].strip
    val = l[(i + 1)..].strip
    if key =~ NAME
      sec = (sections[cur] ||= {})
      out << "line #{n}: duplicate key #{cur}.#{key}" if sec.key?(key)
      sec[key] = val
    else
      out << "line #{n}: syntax error"
    end
  else
    out << "line #{n}: syntax error"
  end
end

# returns [:ok, text] or [:err, msg]
resolve = nil
resolve = lambda do |sec, key, stack|
  full = "#{sec}.#{key}"
  return [:err, "cycle #{(stack + [full]).join(' -> ')}"] if stack.include?(full)
  v = sections.dig(sec, key)
  return [:err, "undefined #{full}"] if v.nil?
  res = +""
  pos = 0
  while (m = REF.match(v, pos))
    res << v[pos...m.begin(0)]
    rs, rk = m[2] ? [m[1], m[2]] : [sec, m[1]]
    r = resolve.call(rs, rk, stack + [full])
    return r if r[0] == :err
    res << r[1]
    pos = m.end(0)
  end
  res << v[pos..]
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
  l = lines[idx]
  idx += 1
  next if l.empty?
  f = l.split(" ")
  if f[0] == "GET" && f.size == 2
    a = f[1].split(".", -1)
    sec, key = a.size == 1 ? ["main", a[0]] : a.size == 2 ? a : [nil, nil]
    if sec && sec =~ NAME && key =~ NAME
      full = "#{sec}.#{key}"
      if sections.dig(sec, key).nil?
        out << "#{full}: not found"
      else
        r = resolve.call(sec, key, [])
        out << (r[0] == :ok ? "#{full} = #{typed.call(r[1])}" : "#{full}: error: #{r[1]}")
      end
    else
      out << "line #{idx}: bad query"
    end
  elsif f[0] == "KEYS" && f.size == 2
    s = sections[f[1]]
    if s.nil?
      out << "#{f[1]}: not found"
    else
      ks = s.keys.sort
      out << "#{f[1]}: #{ks.empty? ? '(none)' : ks.join(', ')}"
    end
  else
    out << "line #{idx}: bad query"
  end
end
puts out

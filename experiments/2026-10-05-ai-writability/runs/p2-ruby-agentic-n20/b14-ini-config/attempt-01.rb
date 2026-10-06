NAME = /\A[a-z0-9_]+\z/
REF = /\$\{([a-z0-9_]+(?:\.[a-z0-9_]+)?)\}/

secs = {} # section => {key => value}
section = "main"
in_queries = false
queries = []

$stdin.each_line.with_index(1) do |raw, no|
  line = raw.strip
  if in_queries
    queries << [no, line] unless line.empty?
    next
  end
  if line == "%%"
    in_queries = true
    next
  end
  next if line.empty? || line.start_with?("#", ";")
  if line =~ /\A\[([a-z0-9_]+)\]\z/
    section = $1
    secs[section] ||= {}
  elsif (i = line.index("="))
    key = line[0, i].strip
    val = line[(i + 1)..].strip
    if key !~ NAME
      puts "line #{no}: syntax error"
      next
    end
    secs[section] ||= {}
    puts "line #{no}: duplicate key #{section}.#{key}" if secs[section].key?(key)
    secs[section][key] = val
  else
    puts "line #{no}: syntax error"
  end
end

class Problem < StandardError; end

resolve = nil
resolve = lambda do |sec, key, stack|
  full = "#{sec}.#{key}"
  raise Problem, "cycle #{(stack[stack.index(full)..] + [full]).join(' -> ')}" if stack.include?(full)
  raise Problem, "undefined #{full}" unless secs.dig(sec, key)
  stack.push(full)
  v = secs[sec][key]
  out = +""
  pos = 0
  v.scan(REF) do
    m = Regexp.last_match
    out << v[pos...m.begin(0)]
    pos = m.end(0)
    ref = m[1]
    s2, k2 = ref.include?(".") ? ref.split(".", 2) : [sec, ref]
    out << resolve.call(s2, k2, stack)
  end
  out << v[pos..]
  stack.pop
  out
end

def typed(v)
  if v =~ /\A[+-]?\d+\z/ then "int #{v.to_i}"
  elsif v =~ /\A(true|yes|on)\z/i then "bool true"
  elsif v =~ /\A(false|no|off)\z/i then "bool false"
  elsif v.include?(",")
    items = v.split(",").map(&:strip).reject(&:empty?)
    items.empty? ? "list[0]" : "list[#{items.size}] #{items.join(' | ')}"
  else
    "str \"#{v}\""
  end
end

queries.each do |no, q|
  w = q.split(/ +/)
  if w.size == 2 && w[0] == "GET"
    n = w[1]
    sec, key = n.include?(".") ? n.split(".", 2) : ["main", n]
    full = "#{sec}.#{key}"
    if secs.dig(sec, key).nil?
      puts "#{full}: not found"
    else
      begin
        puts "#{full} = #{typed(resolve.call(sec, key, []))}"
      rescue Problem => e
        puts "#{full}: error: #{e.message}"
      end
    end
  elsif w.size == 2 && w[0] == "KEYS"
    s = secs[w[1]]
    if s.nil? then puts "#{w[1]}: not found"
    elsif s.empty? then puts "#{w[1]}: (none)"
    else puts "#{w[1]}: #{s.keys.sort_by(&:b).join(', ')}"
    end
  else
    puts "line #{no}: bad query"
  end
end

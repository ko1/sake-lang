NAME = /[a-z0-9_]+/
secs = {}
out = []
cur = "main"
in_q = false
queries = []

class Fail < StandardError; end

resolve = nil
resolve = lambda do |sec, key, stack|
  id = "#{sec}.#{key}"
  if stack.include?(id)
    raise Fail, "cycle #{(stack[stack.index(id)..] + [id]).join(' -> ')}"
  end
  v = $secs.dig(sec, key)
  raise Fail, "undefined #{id}" if v.nil?
  v.gsub(/\$\{(#{NAME}(?:\.#{NAME})?)\}/) do
    ref = $1
    s, k = ref.include?(".") ? ref.split(".", 2) : [sec, ref]
    resolve.call(s, k, stack + [id])
  end
end

$secs = secs
$stdin.each_line.with_index(1) do |raw, n|
  l = raw.strip
  if in_q
    next if l.empty?
    queries << [n, l]
    next
  end
  if l == "%%"
    in_q = true
    next
  end
  next if l.empty? || l.start_with?("#", ";")
  if (m = l.match(/\A\[(#{NAME})\]\z/))
    cur = m[1]
    secs[cur] ||= {}
  elsif (i = l.index("="))
    k = l[0...i].strip
    v = l[(i + 1)..].strip
    if k.match?(/\A#{NAME}\z/)
      secs[cur] ||= {}
      out << "line #{n}: duplicate key #{cur}.#{k}" if secs[cur].key?(k)
      secs[cur][k] = v
    else
      out << "line #{n}: syntax error"
    end
  else
    out << "line #{n}: syntax error"
  end
end

def typed(v)
  if v.match?(/\A[+-]?\d+\z/)
    "int #{v.to_i}"
  elsif v.match?(/\A(true|yes|on)\z/i)
    "bool true"
  elsif v.match?(/\A(false|no|off)\z/i)
    "bool false"
  elsif v.include?(",")
    items = v.split(",", -1).map(&:strip).reject(&:empty?)
    items.empty? ? "list[0]" : "list[#{items.size}] #{items.join(' | ')}"
  else
    "str \"#{v}\""
  end
end

queries.each do |n, l|
  f = l.split(/ +/)
  if f[0] == "GET" && f.size == 2 && f[1].match?(/\A#{NAME}(\.#{NAME})?\z/)
    s, k = f[1].include?(".") ? f[1].split(".", 2) : ["main", f[1]]
    id = "#{s}.#{k}"
    if secs.dig(s, k).nil?
      out << "#{id}: not found"
    else
      begin
        out << "#{id} = #{typed(resolve.call(s, k, []))}"
      rescue Fail => e
        out << "#{id}: error: #{e.message}"
      end
    end
  elsif f[0] == "KEYS" && f.size == 2
    s = f[1]
    if secs.key?(s)
      ks = secs[s].keys.sort
      out << "#{s}: #{ks.empty? ? '(none)' : ks.join(', ')}"
    else
      out << "#{s}: not found"
    end
  else
    out << "line #{n}: bad query"
  end
end
puts out

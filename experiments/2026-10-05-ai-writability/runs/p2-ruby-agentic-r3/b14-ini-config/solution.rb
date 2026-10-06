lines = $stdin.each_line.map { |l| l.chomp.strip }
NM = /\A[a-z0-9_]+\z/
secs = {}
out = []
cur = "main"
i = 0
while i < lines.size
  l = lines[i]; n = i + 1; i += 1
  if l == "%%"
    break
  end
  next if l.empty? || l.start_with?("#") || l.start_with?(";")
  if (md = /\A\[([^\]]*)\]\z/.match(l)) && md[1] =~ NM
    cur = md[1]
    secs[cur] ||= {}
  elsif (k = l.index("="))
    key = l[0, k].strip
    val = l[(k + 1)..].strip
    if key =~ NM
      secs["main"] ||= {} if cur == "main"
      s = (secs[cur] ||= {})
      out << "line #{n}: duplicate key #{cur}.#{key}" if s.key?(key)
      s[key] = val
    else
      out << "line #{n}: syntax error"
    end
  else
    out << "line #{n}: syntax error"
  end
end

class Fail < StandardError; end
$memo = {}
$secs = secs

def resolve(sec, key, stack)
  id = "#{sec}.#{key}"
  return $memo[id] if $memo.key?(id)
  if (p = stack.index(id))
    raise Fail, "cycle " + (stack[p..] + [id]).join(" -> ")
  end
  raw = $secs[sec][key]
  stack2 = stack + [id]
  res = raw.gsub(/\$\{(?:([a-z0-9_]+)\.)?([a-z0-9_]+)\}/) do
    s = $1 || sec; k = $2
    raise Fail, "undefined #{s}.#{k}" unless $secs[s] && $secs[s].key?(k)
    resolve(s, k, stack2)
  end
  $memo[id] = res
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
    items.empty? ? "list[0]" : "list[#{items.size}] #{items.join(' | ')}"
  else
    "str \"#{v}\""
  end
end

while i < lines.size
  l = lines[i]; n = i + 1; i += 1
  next if l.empty?
  w = l.split(" ")
  if w.size == 2 && w[0] == "GET"
    nm = w[1]
    if nm.include?(".")
      sec, key = nm.split(".", 2)
    else
      sec, key = "main", nm
    end
    unless sec =~ NM && key =~ NM
      out << "line #{n}: bad query"; next
    end
    if $secs[sec] && $secs[sec].key?(key)
      begin
        out << "#{sec}.#{key} = #{typed(resolve(sec, key, []))}"
      rescue Fail => e
        out << "#{sec}.#{key}: error: #{e.message}"
      end
    else
      out << "#{sec}.#{key}: not found"
    end
  elsif w.size == 2 && w[0] == "KEYS"
    s = $secs[w[1]]
    if s
      out << "#{w[1]}: " + (s.empty? ? "(none)" : s.keys.sort.join(", "))
    else
      out << "#{w[1]}: not found"
    end
  else
    out << "line #{n}: bad query"
  end
end
puts out

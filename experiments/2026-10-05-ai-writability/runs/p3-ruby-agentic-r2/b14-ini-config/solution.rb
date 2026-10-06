NAME = /\A[a-z0-9_]+\z/
secs = {}
out = []
cur = "main"
lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
split = lines.index { |l| l.strip == "%%" }
conf = split ? lines[0...split] : lines
qs = split ? lines[(split + 1)..] : []
conf.each_with_index do |raw, i|
  n = i + 1
  l = raw.strip
  next if l.empty? || l.start_with?("#", ";")
  if l.start_with?("[")
    if l =~ /\A\[([a-z0-9_]+)\]\z/
      cur = $1
      secs[cur] ||= {}
    else
      out << "line #{n}: syntax error"
    end
  elsif l.include?("=")
    k, v = l.split("=", 2)
    k = k.strip
    if k =~ NAME
      s = (secs[cur] ||= {})
      out << "line #{n}: duplicate key #{cur}.#{k}" if s.key?(k)
      s[k] = v.strip
    else
      out << "line #{n}: syntax error"
    end
  else
    out << "line #{n}: syntax error"
  end
end

class Fail < StandardError; end

def resolve(secs, sec, key, stack)
  id = "#{sec}.#{key}"
  if stack.include?(id)
    raise Fail, "cycle #{(stack + [id]).join(' -> ')}"
  end
  raise Fail, "undefined #{id}" unless secs[sec] && secs[sec].key?(key)
  v = secs[sec][key]
  v.gsub(/\$\{(?:([a-z0-9_]+)\.)?([a-z0-9_]+)\}/) do
    resolve(secs, $1 || sec, $2, stack + [id])
  end
end

qs.each_with_index do |raw, i|
  n = (split ? split + 2 : 0) + i
  w = raw.strip.split(" ")
  next if w.empty?
  if w[0] == "GET" && w.size == 2 && w[1] =~ /\A(?:([a-z0-9_]+)\.)?([a-z0-9_]+)\z/
    sec = $1 || "main"
    key = $2
    id = "#{sec}.#{key}"
    if !(secs[sec] && secs[sec].key?(key))
      out << "#{id}: not found"
      next
    end
    begin
      v = resolve(secs, sec, key, [])
    rescue Fail => e
      out << "#{id}: error: #{e.message}"
      next
    end
    t = if v =~ /\A[+-]?\d+\z/
      "int #{v.to_i}"
    elsif v =~ /\A(true|yes|on)\z/i
      "bool true"
    elsif v =~ /\A(false|no|off)\z/i
      "bool false"
    elsif v.include?(",")
      items = v.split(",").map(&:strip).reject(&:empty?)
      items.empty? ? "list[0]" : "list[#{items.size}] #{items.join(' | ')}"
    else
      "str \"#{v}\""
    end
    out << "#{id} = #{t}"
  elsif w[0] == "KEYS" && w.size == 2
    s = secs[w[1]]
    out << (s ? "#{w[1]}: #{s.empty? ? '(none)' : s.keys.sort.join(', ')}" : "#{w[1]}: not found")
  else
    out << "line #{n}: bad query"
  end
end
puts out

NM = /\A[a-z0-9_]+\z/
secs = {}
out = []
raw = $stdin.each_line.map { |l| l.strip }
sec = "main"
qi = nil
raw.each_with_index do |l, i|
  n = i + 1
  if l == "%%"
    qi = i + 1
    break
  end
  next if l.empty? || l.start_with?("#", ";")
  if l =~ /\A\[([a-z0-9_]+)\]\z/
    sec = $1
    secs[sec] ||= {}
  elsif l.include?("=")
    k, v = l.split("=", 2)
    k = k.strip
    v = v.strip
    if k =~ NM
      secs[sec] ||= {}
      out << "line #{n}: duplicate key #{sec}.#{k}" if secs[sec].key?(k)
      secs[sec][k] = v
    else
      out << "line #{n}: syntax error"
    end
  else
    out << "line #{n}: syntax error"
  end
end

class Fail < StandardError; end
memo = {}
resolve = nil
resolve = lambda do |s, k, stack|
  id = "#{s}.#{k}"
  return memo[id] if memo.key?(id)
  if (j = stack.index(id))
    raise Fail, "cycle " + (stack[j..] + [id]).join(" -> ")
  end
  v = secs[s][k]
  stack.push(id)
  res = v.gsub(/\$\{([a-z0-9_]+)(?:\.([a-z0-9_]+))?\}/) do
    a, b = $1, $2
    rs, rk = b ? [a, b] : [s, a]
    raise Fail, "undefined #{rs}.#{rk}" unless secs[rs] && secs[rs].key?(rk)
    resolve.call(rs, rk, stack)
  end
  stack.pop
  memo[id] = res
end

typed = lambda do |v|
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

if qi
  raw[qi..].each_with_index do |l, i|
    n = qi + i + 1
    next if l.empty?
    w = l.split(" ")
    if w[0] == "GET" && w.size == 2 && w[1] =~ /\A[a-z0-9_]+(\.[a-z0-9_]+)?\z/
      s, k = w[1].include?(".") ? w[1].split(".") : ["main", w[1]]
      id = "#{s}.#{k}"
      if !(secs[s] && secs[s].key?(k))
        out << "#{id}: not found"
      else
        begin
          out << "#{id} = #{typed.call(resolve.call(s, k, []))}"
        rescue Fail => e
          out << "#{id}: error: #{e.message}"
        end
      end
    elsif w[0] == "KEYS" && w.size == 2
      s = w[1]
      if secs[s]
        ks = secs[s].keys.sort
        out << "#{s}: #{ks.empty? ? "(none)" : ks.join(", ")}"
      else
        out << "#{s}: not found"
      end
    else
      out << "line #{n}: bad query"
    end
  end
end
puts out

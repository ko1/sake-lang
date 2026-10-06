lines = $stdin.read.to_s.split("\n").map { |l| l.chomp("\r") }
nm = /\A[a-z0-9_]+\z/
secs = { }
cur = "main"
out = []
idx = 0
while idx < lines.size
  line = lines[idx].strip
  n = idx + 1
  idx += 1
  break if line == "%%"
  next if line.empty? || line.start_with?("#") || line.start_with?(";")
  if line =~ /\A\[([a-z0-9_]+)\]\z/
    cur = $1
    secs[cur] ||= {}
  elsif line.include?("=")
    k, v = line.split("=", 2)
    k = k.strip
    v = v.strip
    if k =~ nm
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

class Fail < StandardError; end

def resolve(secs, s, k, stack)
  v = secs[s][k]
  stack = stack + ["#{s}.#{k}"]
  v.gsub(/\$\{([a-z0-9_]+(?:\.[a-z0-9_]+)?)\}/) do
    ref = $1
    rs, rk = ref.include?(".") ? ref.split(".", 2) : [s, ref]
    full = "#{rs}.#{rk}"
    raise Fail, "undefined #{full}" unless secs[rs] && secs[rs].key?(rk)
    raise Fail, "cycle " + (stack + [full]).join(" -> ") if stack.include?(full)
    resolve(secs, rs, rk, stack)
  end
end

def typed(v)
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
  line = lines[idx].strip
  n = idx + 1
  idx += 1
  next if line.empty?
  w = line.split(" ")
  if w[0] == "GET" && w.size == 2
    name = w[1]
    if name =~ /\A([a-z0-9_]+)\.([a-z0-9_]+)\z/
      s, k = $1, $2
    elsif name =~ nm
      s, k = "main", name
    else
      out << "line #{n}: bad query"
      next
    end
    if secs[s] && secs[s].key?(k)
      begin
        out << "#{s}.#{k} = #{typed(resolve(secs, s, k, []))}"
      rescue Fail => e
        out << "#{s}.#{k}: error: #{e.message}"
      end
    else
      out << "#{s}.#{k}: not found"
    end
  elsif w[0] == "KEYS" && w.size == 2
    s = w[1]
    if secs[s]
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

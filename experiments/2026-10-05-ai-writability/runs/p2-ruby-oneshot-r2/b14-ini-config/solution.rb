class Fail < StandardError; end

lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
NM = /\A[a-z0-9_]+\z/
secs = {}
msgs = []
cur = "main"
qstart = nil
lines.each_with_index do |raw, i|
  n = i + 1
  line = raw.strip
  if line == "%%"
    qstart = i + 1
    break
  end
  next if line.empty? || line.start_with?("#") || line.start_with?(";")
  if line =~ /\A\[([a-z0-9_]+)\]\z/
    cur = $1
    secs[cur] ||= {}
  elsif (idx = line.index("="))
    key = line[0...idx].strip
    val = line[(idx + 1)..].strip
    if key =~ NM
      secs[cur] ||= {}
      if secs[cur].key?(key)
        msgs << "line #{n}: duplicate key #{cur}.#{key}"
      end
      secs[cur][key] = val
    else
      msgs << "line #{n}: syntax error"
    end
  else
    msgs << "line #{n}: syntax error"
  end
end

REF = /\$\{([a-z0-9_]+(?:\.[a-z0-9_]+)?)\}/

def resolve(secs, sec, key, stack)
  id = "#{sec}.#{key}"
  if stack.include?(id)
    i = stack.index(id)
    raise Fail, "cycle " + (stack[i..] + [id]).join(" -> ")
  end
  val = secs[sec][key]
  stack2 = stack + [id]
  val.gsub(REF) do
    ref = $1
    rs, rk = ref.include?(".") ? ref.split(".", 2) : [sec, ref]
    raise Fail, "undefined #{rs}.#{rk}" unless secs[rs] && secs[rs].key?(rk)
    resolve(secs, rs, rk, stack2)
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

out = msgs.dup
if qstart
  (qstart...lines.size).each do |i|
    n = i + 1
    line = lines[i].strip
    next if line.empty?
    w = line.split(" ")
    if w.size == 2 && w[0] == "GET" && (w[1] =~ /\A[a-z0-9_]+\.[a-z0-9_]+\z/ || w[1] =~ NM)
      sec, key = w[1].include?(".") ? w[1].split(".", 2) : ["main", w[1]]
      id = "#{sec}.#{key}"
      if secs[sec] && secs[sec].key?(key)
        begin
          v = resolve(secs, sec, key, [])
          out << "#{id} = #{typed(v)}"
        rescue Fail => e
          out << "#{id}: error: #{e.message}"
        end
      else
        out << "#{id}: not found"
      end
    elsif w.size == 2 && w[0] == "KEYS"
      s = w[1]
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
end
puts out

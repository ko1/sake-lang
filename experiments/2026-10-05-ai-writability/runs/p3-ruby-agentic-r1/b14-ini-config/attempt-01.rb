NAME = /[a-z0-9_]+/
lines = $stdin.read.split("\n", -1).map { |l| l.strip }
secs = {}
out = []
cur = "main"
inq = false
qs = []
lines.each_with_index do |line, i|
  n = i + 1
  if inq
    qs << [n, line]
    next
  end
  if line == "%%"
    inq = true; next
  end
  next if line.empty? || line.start_with?("#", ";")
  if (m = /\A\[(#{NAME})\]\z/.match(line))
    cur = m[1]
    secs[cur] ||= {}
  elsif (m = /\A([^=]*)=(.*)\z/.match(line)) && m[1].strip =~ /\A#{NAME}\z/
    k = m[1].strip
    secs[cur] ||= {}
    out << "line #{n}: duplicate key #{cur}.#{k}" if secs[cur].key?(k)
    secs[cur][k] = m[2].strip
  else
    out << "line #{n}: syntax error"
  end
end

class Fail < StandardError; end

resolve = nil
resolve = lambda do |sec, key, stack|
  id = "#{sec}.#{key}"
  raise Fail, "cycle #{(stack + [id]).join(' -> ')}" if stack.include?(id)
  v = secs[sec] && secs[sec][key]
  raise Fail, "undefined #{id}" if v.nil?
  v.gsub(/\$\{(#{NAME})(?:\.(#{NAME}))?\}/) do
    a, b = $1, $2
    s, k = b ? [a, b] : [sec, a]
    resolve.(s, k, stack + [id])
  end
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
    items.empty? ? "list[0]" : "list[#{items.size}] #{items.join(' | ')}"
  else
    "str \"#{v}\""
  end
end

qs.each do |n, line|
  next if line.empty?
  f = line.split(" ")
  if f.size == 2 && f[0] == "GET" && f[1] =~ /\A#{NAME}(\.#{NAME})?\z/
    s, k = f[1].include?(".") ? f[1].split(".") : ["main", f[1]]
    id = "#{s}.#{k}"
    if secs[s] && secs[s].key?(k)
      begin
        out << "#{id} = #{typed.(resolve.(s, k, []))}"
      rescue Fail => e
        out << "#{id}: error: #{e.message}"
      end
    else
      out << "#{id}: not found"
    end
  elsif f.size == 2 && f[0] == "KEYS"
    if secs[f[1]]
      ks = secs[f[1]].keys.sort
      out << "#{f[1]}: #{ks.empty? ? '(none)' : ks.join(', ')}"
    else
      out << "#{f[1]}: not found"
    end
  else
    out << "line #{n}: bad query"
  end
end
puts out

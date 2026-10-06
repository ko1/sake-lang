NAME = /\A[a-z0-9_]+\z/
lines = STDIN.read.split("\n", -1)
lines.pop if lines.last == ''
sections = {}
cur = 'main'
out = []
qstart = nil
lines.each_with_index do |raw, i|
  n = i + 1
  l = raw.strip
  if l == '%%'
    qstart = i + 1
    break
  end
  next if l.empty? || l.start_with?('#') || l.start_with?(';')
  if l =~ /\A\[([a-z0-9_]+)\]\z/
    cur = $1
    sections[cur] ||= {}
  elsif (idx = l.index('='))
    k = l[0, idx].strip
    v = l[(idx + 1)..].strip
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

class ResolveError < StandardError; end
$memo = {}
$sections = sections

def resolve(sec, key, stack)
  full = "#{sec}.#{key}"
  if (i = stack.index(full))
    raise ResolveError, "cycle " + (stack[i..] + [full]).join(' -> ')
  end
  return $memo[full] if $memo.key?(full)
  val = $sections[sec][key]
  stack.push(full)
  res = val.gsub(/\$\{([a-z0-9_]+(?:\.[a-z0-9_]+)?)\}/) do
    ref = $1
    if ref.include?('.')
      s, k = ref.split('.', 2)
    else
      s = sec; k = ref
    end
    if stack.include?("#{s}.#{k}")
      raise ResolveError, "cycle " + (stack[stack.index("#{s}.#{k}")..] + ["#{s}.#{k}"]).join(' -> ')
    end
    unless $sections[s] && $sections[s].key?(k)
      raise ResolveError, "undefined #{s}.#{k}"
    end
    resolve(s, k, stack)
  end
  stack.pop
  $memo[full] = res
  res
end

def typed(v)
  if v =~ /\A[+-]?\d+\z/
    "int #{v.to_i}"
  elsif %w[true yes on].include?(v.downcase)
    "bool true"
  elsif %w[false no off].include?(v.downcase)
    "bool false"
  elsif v.include?(',')
    items = v.split(',', -1).map(&:strip).reject(&:empty?)
    items.empty? ? "list[0]" : "list[#{items.size}] #{items.join(' | ')}"
  else
    "str \"#{v}\""
  end
end

if qstart
  lines[qstart..].each_with_index do |raw, j|
    n = qstart + j + 1
    l = raw.strip
    next if l.empty?
    w = l.split(/ +/)
    if w.size == 2 && w[0] == 'GET'
      nm = w[1]
      if nm.include?('.')
        s, k = nm.split('.', 2)
      else
        s = 'main'; k = nm
      end
      if sections[s] && sections[s].key?(k)
        begin
          out << "#{s}.#{k} = #{typed(resolve(s, k, []))}"
        rescue ResolveError => e
          out << "#{s}.#{k}: error: #{e.message}"
        end
      else
        out << "#{s}.#{k}: not found"
      end
    elsif w.size == 2 && w[0] == 'KEYS'
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
end
puts out

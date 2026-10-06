BUILTIN = %w[+ - * / mod = < > dup drop swap over . if else then : ;].freeze
class Syn < StandardError; end
class RunErr < StandardError; end

def num?(t) = t.match?(/\A-?\d+\z/)

# returns [nodes, terminator, next_index]
def parse_block(tk, i, in_def, in_if)
  nodes = []
  while i < tk.size
    t = tk[i]
    case t
    when "if"
      th, term, i = parse_block(tk, i + 1, in_def, true)
      el = nil
      if term == "else"
        el, term, i = parse_block(tk, i, in_def, true)
        raise Syn unless term == "then"
      elsif term != "then"
        raise Syn
      end
      nodes << [:if, th, el]
    when ":"
      raise Syn if in_def || in_if
      name = tk[i + 1]
      raise Syn if name.nil? || num?(name) || BUILTIN.include?(name)
      body, term, i = parse_block(tk, i + 2, true, false)
      raise Syn unless term == ";"
      nodes << [:def, name, body]
    when "else", "then", ";"
      return [nodes, t, i + 1]
    else
      nodes << (num?(t) ? [:num, t.to_i] : [:word, t])
    end
    i += 1 if t != "if" && t != ":"
  end
  [nodes, nil, i]
end

$stack = []
$dict = {}
$depth = 0

def need(n, w)
  raise RunErr, "stack underflow in #{w}" if $stack.size < n
end

def run(nodes)
  nodes.each do |n|
    case n[0]
    when :num then $stack.push(n[1])
    when :def then $dict[n[1]] = n[2]
    when :if
      need(1, "if")
      v = $stack.pop
      if v != 0 then run(n[1])
      elsif n[2] then run(n[2])
      end
    when :word then word(n[1])
    end
  end
end

def word(w)
  s = $stack
  case w
  when "+", "-", "*", "=", "<", ">"
    need(2, w)
    b = s.pop
    a = s.pop
    s.push(case w
           when "+" then a + b
           when "-" then a - b
           when "*" then a * b
           when "=" then a == b ? 1 : 0
           when "<" then a < b ? 1 : 0
           else a > b ? 1 : 0
           end)
  when "/", "mod"
    need(2, w)
    raise RunErr, "division by zero" if s[-1] == 0
    b = s.pop
    a = s.pop
    if w == "/"
      q = a.abs / b.abs
      q = -q if (a < 0) != (b < 0)
      s.push(q)
    else
      s.push(a.remainder(b))
    end
  when "dup" then need(1, w); s.push(s[-1])
  when "drop" then need(1, w); s.pop
  when "swap" then need(2, w); s[-1], s[-2] = s[-2], s[-1]
  when "over" then need(2, w); s.push(s[-2])
  when "."
    need(1, w)
    puts s.pop
  else
    body = $dict[w]
    raise RunErr, "unknown word #{w}" unless body
    raise RunErr, "too deep" if $depth >= 100
    $depth += 1
    begin
      run(body)
    ensure
      $depth -= 1
    end
  end
end

$stdin.each_line.with_index(1) do |raw, no|
  tk = raw.chomp.split(" ")
  begin
    nodes, term, = parse_block(tk, 0, false, false)
    raise Syn if term
  rescue Syn
    puts "line #{no}: syntax error"
    next
  end
  saved = $stack.dup
  $depth = 0
  begin
    run(nodes)
  rescue RunErr => e
    $stack = saved
    puts "line #{no}: error: #{e.message}"
  end
end
puts $stack.empty? ? "stack: (empty)" : "stack: #{$stack.join(' ')}"

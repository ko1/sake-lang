BUILTINS = %w[+ - * / mod = < > dup drop swap over . if else then : ;].freeze
NUM = /\A-?\d+\z/

class RunError < StandardError; end

# Returns false on syntax error, else a node list (defs included).
def parse(toks)
  i = 0
  # frames: [kind, nodes, extra]; kinds :top, :def, :if (then part), :else
  frames = [[:top, [], nil]]
  while i < toks.size
    t = toks[i]
    i += 1
    case t
    when ":"
      return false unless frames.size == 1
      name = toks[i]
      return false if name.nil? || name =~ NUM || BUILTINS.include?(name)
      i += 1
      frames << [:def, [], name]
    when ";"
      return false unless frames.last[0] == :def
      f = frames.pop
      frames.last[1] << [:def, f[2], f[1]]
    when "if"
      frames << [:if, [], nil]
    when "else"
      return false unless frames.last[0] == :if
      f = frames.last
      frames[-1] = [:else, [], f[1]]
    when "then"
      k = frames.last[0]
      return false unless k == :if || k == :else
      f = frames.pop
      node = k == :if ? [:if, f[1], []] : [:if, f[2], f[1]]
      frames.last[1] << node
    else
      frames.last[1] << (t =~ NUM ? [:num, t.to_i] : [:word, t])
    end
  end
  return false unless frames.size == 1
  frames[0][1]
end

$stack = []
$defs = {}
$depth = 0

def pop_n(n, w)
  raise RunError, "stack underflow in #{w}" if $stack.size < n
end

def run(nodes)
  nodes.each do |n|
    case n[0]
    when :num then $stack << n[1]
    when :def then $defs[n[1]] = n[2]
    when :if
      pop_n(1, "if")
      v = $stack.pop
      run(v != 0 ? n[1] : n[2])
    when :word then word(n[1])
    end
  end
end

def word(w)
  s = $stack
  case w
  when "+", "-", "*"
    pop_n(2, w)
    b = s.pop
    a = s.pop
    s << a.send(w, b)
  when "/", "mod"
    pop_n(2, w)
    b = s.pop
    a = s.pop
    raise RunError, "division by zero" if b == 0
    q = a.abs / b.abs
    q = -q if (a < 0) != (b < 0)
    s << (w == "/" ? q : a - q * b)
  when "=", "<", ">"
    pop_n(2, w)
    b = s.pop
    a = s.pop
    r = case w when "=" then a == b when "<" then a < b else a > b end
    s << (r ? 1 : 0)
  when "dup"
    pop_n(1, w)
    s << s.last
  when "drop"
    pop_n(1, w)
    s.pop
  when "swap"
    pop_n(2, w)
    s[-1], s[-2] = s[-2], s[-1]
  when "over"
    pop_n(2, w)
    s << s[-2]
  when "."
    pop_n(1, w)
    puts s.pop
  else
    body = $defs[w]
    raise RunError, "unknown word #{w}" unless body
    raise RunError, "too deep" if $depth >= 100
    $depth += 1
    begin
      run(body)
    ensure
      $depth -= 1
    end
  end
end

$stdin.each_line.with_index(1) do |line, no|
  toks = line.chomp.split(/ +/).reject(&:empty?)
  ast = parse(toks)
  unless ast
    puts "line #{no}: syntax error"
    next
  end
  saved = $stack.dup
  $depth = 0
  begin
    run(ast)
  rescue RunError => e
    $stack = saved
    puts "line #{no}: error: #{e.message}"
  end
end
puts $stack.empty? ? "stack: (empty)" : "stack: #{$stack.join(' ')}"

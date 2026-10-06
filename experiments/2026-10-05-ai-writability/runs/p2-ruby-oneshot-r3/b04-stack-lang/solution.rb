BUILTINS = %w[+ - * / mod = < > dup drop swap over . if else then : ;].freeze
NUM = /\A-?\d+\z/

class RunError < StandardError; end

def syntax_ok?(toks)
  in_def = false
  ifs = []
  i = 0
  while i < toks.size
    t = toks[i]
    case t
    when ":"
      return false if in_def || !ifs.empty?
      name = toks[i + 1]
      return false if name.nil? || name =~ NUM || BUILTINS.include?(name)
      in_def = true
      i += 1
    when ";"
      return false if !in_def || !ifs.empty?
      in_def = false
    when "if"
      ifs << :if
    when "else"
      return false if ifs.last != :if
      ifs[-1] = :else
    when "then"
      return false if ifs.empty?
      ifs.pop
    end
    i += 1
  end
  !in_def && ifs.empty?
end

def parse_seq(toks, pos)
  nodes = []
  while pos < toks.size
    tok = toks[pos]
    case tok
    when "if"
      th, pos, term = parse_seq(toks, pos + 1)
      el = []
      el, pos, _ = parse_seq(toks, pos) if term == "else"
      nodes << [:if, th, el]
    when "else", "then", ";"
      return [nodes, pos + 1, tok]
    when ":"
      name = toks[pos + 1]
      body, pos, _ = parse_seq(toks, pos + 2)
      nodes << [:def, name, body]
    else
      nodes << tok
      pos += 1
    end
  end
  [nodes, pos, nil]
end

$stack = []
$dict = {}
$depth = 0

def need(n, w)
  raise RunError, "stack underflow in #{w}" if $stack.size < n
end

def run(nodes)
  nodes.each do |n|
    if n.is_a?(Array)
      if n[0] == :def
        $dict[n[1]] = n[2]
      else
        need(1, "if")
        v = $stack.pop
        run(v != 0 ? n[1] : n[2])
      end
      next
    end
    if n =~ NUM
      $stack.push(n.to_i)
      next
    end
    case n
    when "+", "-", "*", "=", "<", ">", "/", "mod"
      need(2, n)
      b = $stack.pop
      a = $stack.pop
      r =
        case n
        when "+" then a + b
        when "-" then a - b
        when "*" then a * b
        when "=" then a == b ? 1 : 0
        when "<" then a < b ? 1 : 0
        when ">" then a > b ? 1 : 0
        when "/"
          raise RunError, "division by zero" if b == 0
          q = a.abs / b.abs
          (a < 0) != (b < 0) ? -q : q
        when "mod"
          raise RunError, "division by zero" if b == 0
          a.remainder(b)
        end
      $stack.push(r)
    when "dup"
      need(1, n)
      $stack.push($stack.last)
    when "drop"
      need(1, n)
      $stack.pop
    when "swap"
      need(2, n)
      $stack[-1], $stack[-2] = $stack[-2], $stack[-1]
    when "over"
      need(2, n)
      $stack.push($stack[-2])
    when "."
      need(1, n)
      puts $stack.pop
    else
      body = $dict[n]
      raise RunError, "unknown word #{n}" if body.nil?
      raise RunError, "too deep" if $depth >= 100
      $depth += 1
      begin
        run(body)
      ensure
        $depth -= 1
      end
    end
  end
end

$stdin.each_line.with_index(1) do |raw, no|
  toks = raw.chomp.delete("\r").split(/ +/).reject(&:empty?)
  unless syntax_ok?(toks)
    puts "line #{no}: syntax error"
    next
  end
  nodes, = parse_seq(toks, 0)
  saved = $stack.dup
  $depth = 0
  begin
    run(nodes)
  rescue RunError => e
    $stack = saved
    puts "line #{no}: error: #{e.message}"
  end
end

if $stack.empty?
  puts "stack: (empty)"
else
  puts "stack: #{$stack.join(" ")}"
end

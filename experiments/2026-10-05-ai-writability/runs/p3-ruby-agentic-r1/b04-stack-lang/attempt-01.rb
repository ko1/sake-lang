class SyntaxErr < StandardError; end
class RunErr < StandardError; end

BUILTINS = %w[+ - * / mod = < > dup drop swap over . if else then : ;]
ARITY = { "+" => 2, "-" => 2, "*" => 2, "/" => 2, "mod" => 2, "=" => 2, "<" => 2, ">" => 2,
          "dup" => 1, "drop" => 1, "swap" => 2, "over" => 2, "." => 1 }

# returns [items, terminator]; mode: :top, :def, :if
def parse_seq(toks, pos, mode)
  items = []
  while pos[0] < toks.size
    t = toks[pos[0]]
    pos[0] += 1
    case t
    when ":"
      raise SyntaxErr if mode != :top
      raise SyntaxErr if pos[0] >= toks.size
      name = toks[pos[0]]
      pos[0] += 1
      raise SyntaxErr if name =~ /\A-?\d+\z/ || BUILTINS.include?(name)
      body, term = parse_seq(toks, pos, :def)
      raise SyntaxErr unless term == ";"
      items << [:def, name, body]
    when ";"
      raise SyntaxErr if mode != :def
      return [items, ";"]
    when "else"
      raise SyntaxErr if mode != :if
      return [items, "else"]
    when "then"
      raise SyntaxErr if mode != :if
      return [items, "then"]
    when "if"
      a, term = parse_seq(toks, pos, :if)
      b = nil
      if term == "else"
        b, term = parse_seq(toks, pos, :if)
        raise SyntaxErr unless term == "then"
      elsif term != "then"
        raise SyntaxErr
      end
      items << [:if, a, b]
    when /\A-?\d+\z/
      items << [:num, t.to_i]
    else
      items << [:word, t]
    end
  end
  [items, nil]
end

$stack = []
$dict = {}
$depth = 0

def run(items)
  items.each do |it|
    case it[0]
    when :num then $stack.push(it[1])
    when :def then $dict[it[1]] = it[2]
    when :if
      raise RunErr, "stack underflow in if" if $stack.empty?
      v = $stack.pop
      if v != 0
        run(it[1])
      elsif it[2]
        run(it[2])
      end
    when :word
      w = it[1]
      if ARITY.key?(w)
        raise RunErr, "stack underflow in #{w}" if $stack.size < ARITY[w]
        builtin(w)
      elsif $dict.key?(w)
        raise RunErr, "too deep" if $depth >= 100
        $depth += 1
        begin
          run($dict[w])
        ensure
          $depth -= 1
        end
      else
        raise RunErr, "unknown word #{w}"
      end
    end
  end
end

def builtin(w)
  s = $stack
  case w
  when "+" then b = s.pop; a = s.pop; s << a + b
  when "-" then b = s.pop; a = s.pop; s << a - b
  when "*" then b = s.pop; a = s.pop; s << a * b
  when "/", "mod"
    raise RunErr, "division by zero" if s[-1] == 0
    b = s.pop; a = s.pop
    q = a.abs / b.abs
    q = -q if (a < 0) != (b < 0)
    s << (w == "/" ? q : a - b * q)
  when "=" then b = s.pop; a = s.pop; s << (a == b ? 1 : 0)
  when "<" then b = s.pop; a = s.pop; s << (a < b ? 1 : 0)
  when ">" then b = s.pop; a = s.pop; s << (a > b ? 1 : 0)
  when "dup" then s << s[-1]
  when "drop" then s.pop
  when "swap" then b = s.pop; a = s.pop; s << b << a
  when "over" then s << s[-2]
  when "." then puts s.pop.to_s
  end
end

$stdin.each_line.with_index(1) do |line, n|
  toks = line.chomp.split(" ")
  begin
    items, = parse_seq(toks, [0], :top)
  rescue SyntaxErr
    puts "line #{n}: syntax error"
    next
  end
  saved = $stack.dup
  $depth = 0
  begin
    run(items)
  rescue RunErr => e
    $stack = saved
    puts "line #{n}: error: #{e.message}"
  end
end
puts $stack.empty? ? "stack: (empty)" : "stack: #{$stack.join(' ')}"

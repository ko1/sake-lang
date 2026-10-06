BUILTINS = %w[+ - * / mod = < > dup drop swap over . if else then : ;]
ARITY = {"+" => 2, "-" => 2, "*" => 2, "/" => 2, "mod" => 2, "=" => 2, "<" => 2, ">" => 2,
         "dup" => 1, "drop" => 1, "swap" => 2, "over" => 2, "." => 1}

class Syn < StandardError; end
class RunErr < StandardError; end

# parse items until a terminator in `stops`; returns [items, terminator]
def parse_seq(toks, pos, stops, in_def)
  items = []
  loop do
    t = toks[pos[0]]
    raise Syn if t.nil? && !stops.empty?
    return [items, nil] if t.nil?
    pos[0] += 1
    if stops.include?(t)
      return [items, t]
    elsif t == ":"
      raise Syn if in_def
      raise Syn if stops != []  # inside an if
      name = toks[pos[0]]
      raise Syn if name.nil? || name =~ /\A-?\d+\z/ || BUILTINS.include?(name)
      pos[0] += 1
      body, = parse_seq(toks, pos, [";"], true)
      items << [:def, name, body]
    elsif t == "if"
      a, term = parse_seq(toks, pos, %w[else then], in_def)
      b = nil
      b, = parse_seq(toks, pos, %w[then], in_def) if term == "else"
      items << [:if, a, b]
    elsif t == "else" || t == "then" || t == ";"
      raise Syn
    elsif t =~ /\A-?\d+\z/
      items << [:num, t.to_i]
    else
      items << [:word, t]
    end
  end
end

$stack = []
$defs = {}
$depth = 0

def need(w, n)
  raise RunErr, "stack underflow in #{w}" if $stack.size < n
end

def run(items)
  items.each do |it|
    case it[0]
    when :num then $stack << it[1]
    when :def then $defs[it[1]] = it[2]
    when :if
      need("if", 1)
      v = $stack.pop
      if v != 0
        run(it[1])
      elsif it[2]
        run(it[2])
      end
    when :word
      w = it[1]
      if ARITY.key?(w)
        need(w, ARITY[w])
        case w
        when "+" then b = $stack.pop; a = $stack.pop; $stack << a + b
        when "-" then b = $stack.pop; a = $stack.pop; $stack << a - b
        when "*" then b = $stack.pop; a = $stack.pop; $stack << a * b
        when "/", "mod"
          b = $stack.pop; a = $stack.pop
          raise RunErr, "division by zero" if b == 0
          if w == "/"
            q = a.abs / b.abs
            q = -q if (a < 0) != (b < 0)
            $stack << q
          else
            $stack << a.remainder(b)
          end
        when "=" then b = $stack.pop; a = $stack.pop; $stack << (a == b ? 1 : 0)
        when "<" then b = $stack.pop; a = $stack.pop; $stack << (a < b ? 1 : 0)
        when ">" then b = $stack.pop; a = $stack.pop; $stack << (a > b ? 1 : 0)
        when "dup" then $stack << $stack[-1]
        when "drop" then $stack.pop
        when "swap" then $stack[-1], $stack[-2] = $stack[-2], $stack[-1]
        when "over" then $stack << $stack[-2]
        when "." then puts $stack.pop
        end
      elsif $defs.key?(w)
        raise RunErr, "too deep" if $depth >= 100
        $depth += 1
        begin
          run($defs[w])
        ensure
          $depth -= 1
        end
      else
        raise RunErr, "unknown word #{w}"
      end
    end
  end
end

$stdin.each_line.with_index(1) do |raw, n|
  toks = raw.chomp.split(" ")
  begin
    prog, = parse_seq(toks, [0], [], false)
  rescue Syn
    puts "line #{n}: syntax error"
    next
  end
  saved = $stack.dup
  $depth = 0
  begin
    run(prog)
  rescue RunErr => e
    $stack = saved
    puts "line #{n}: error: #{e.message}"
  end
end
puts $stack.empty? ? "stack: (empty)" : "stack: #{$stack.join(" ")}"

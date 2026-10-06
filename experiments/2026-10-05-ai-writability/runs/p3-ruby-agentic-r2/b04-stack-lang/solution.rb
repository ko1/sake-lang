class SyntaxErr < StandardError; end
class RunErr < StandardError; end

BUILTINS = %w[+ - * / mod = < > dup drop swap over . if else then : ;].freeze
ARITY = { "+" => 2, "-" => 2, "*" => 2, "/" => 2, "mod" => 2, "=" => 2, "<" => 2, ">" => 2,
          "dup" => 1, "drop" => 1, "swap" => 2, "over" => 2, "." => 1 }.freeze

# returns [items, pos, terminator]
def parse_seq(toks, pos, mode)
  items = []
  while pos < toks.size
    t = toks[pos]
    case t
    when "else", "then", ";"
      return [items, pos, t]
    when ":"
      raise SyntaxErr unless mode == :top
      name = toks[pos + 1]
      raise SyntaxErr if name.nil? || name =~ /\A-?\d+\z/ || BUILTINS.include?(name)
      body, pos, term = parse_seq(toks, pos + 2, :def)
      raise SyntaxErr unless term == ";"
      items << [:def, name, body]
      pos += 1
    when "if"
      th, pos, term = parse_seq(toks, pos + 1, :then)
      el = nil
      if term == "else"
        el, pos, term = parse_seq(toks, pos + 1, :else)
        raise SyntaxErr unless term == "then"
      else
        raise SyntaxErr unless term == "then"
      end
      items << [:if, th, el]
      pos += 1
    when /\A-?\d+\z/
      items << [:num, t.to_i]
      pos += 1
    else
      items << [:word, t]
      pos += 1
    end
  end
  [items, pos, nil]
end

$dict = {}
$stack = []
$depth = 0

def run(items)
  items.each do |it|
    case it[0]
    when :num
      $stack.push(it[1])
    when :def
      $dict[it[1]] = it[2]
    when :if
      raise RunErr, "stack underflow in if" if $stack.empty?
      c = $stack.pop
      if c != 0
        run(it[1])
      elsif it[2]
        run(it[2])
      end
    when :word
      w = it[1]
      if ARITY.key?(w)
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
  raise RunErr, "stack underflow in #{w}" if s.size < ARITY[w]
  case w
  when "+" then b = s.pop; a = s.pop; s.push(a + b)
  when "-" then b = s.pop; a = s.pop; s.push(a - b)
  when "*" then b = s.pop; a = s.pop; s.push(a * b)
  when "/", "mod"
    b = s.pop
    a = s.pop
    raise RunErr, "division by zero" if b == 0
    q = a.abs / b.abs
    q = -q if (a < 0) != (b < 0)
    s.push(w == "/" ? q : a - q * b)
  when "=" then b = s.pop; a = s.pop; s.push(a == b ? 1 : 0)
  when "<" then b = s.pop; a = s.pop; s.push(a < b ? 1 : 0)
  when ">" then b = s.pop; a = s.pop; s.push(a > b ? 1 : 0)
  when "dup" then s.push(s.last)
  when "drop" then s.pop
  when "swap" then b = s.pop; a = s.pop; s.push(b, a)
  when "over" then s.push(s[-2])
  when "." then puts s.pop
  end
end

$stdin.each_line.with_index(1) do |raw, no|
  toks = raw.chomp.split(/ +/).reject(&:empty?)
  begin
    items, _, term = parse_seq(toks, 0, :top)
    raise SyntaxErr if term
  rescue SyntaxErr
    puts "line #{no}: syntax error"
    next
  end
  saved = $stack.dup
  $depth = 0
  begin
    run(items)
  rescue RunErr => e
    $stack = saved
    puts "line #{no}: error: #{e.message}"
  end
end
puts $stack.empty? ? "stack: (empty)" : "stack: #{$stack.join(" ")}"

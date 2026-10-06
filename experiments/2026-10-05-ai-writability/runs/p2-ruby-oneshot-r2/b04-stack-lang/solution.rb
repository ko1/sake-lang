BUILTINS = %w[+ - * / mod = < > dup drop swap over . if else then : ;]
NUM = /\A-?\d+\z/

class LangError < StandardError; end

def syntax_ok?(toks)
  st = []
  i = 0
  while i < toks.size
    t = toks[i]
    case t
    when "if"
      st << [:if, false]
    when "else"
      return false if st.empty? || st.last[0] != :if || st.last[1]
      st.last[1] = true
    when "then"
      return false if st.empty? || st.last[0] != :if
      st.pop
    when ":"
      return false unless st.empty?
      i += 1
      return false if i >= toks.size
      n = toks[i]
      return false if n =~ NUM || BUILTINS.include?(n)
      st << [:def]
    when ";"
      return false if st.empty? || st.last[0] != :def
      st.pop
    end
    i += 1
  end
  st.empty?
end

# Returns list of nodes up to a terminator token (else/then/;) or end.
def parse_seq(toks, pos)
  out = []
  while pos[0] < toks.size
    t = toks[pos[0]]
    case t
    when "else", "then", ";"
      return out
    when "if"
      pos[0] += 1
      a = parse_seq(toks, pos)
      b = []
      if toks[pos[0]] == "else"
        pos[0] += 1
        b = parse_seq(toks, pos)
      end
      pos[0] += 1 # then
      out << [:if, a, b]
    when ":"
      name = toks[pos[0] + 1]
      pos[0] += 2
      body = parse_seq(toks, pos)
      pos[0] += 1 # ;
      out << [:def, name, body]
    else
      pos[0] += 1
      out << (t =~ NUM ? [:num, t.to_i] : [:word, t])
    end
  end
  out
end

$stack = []
$defs = {}
$depth = 0

def need(n, w)
  raise LangError, "stack underflow in #{w}" if $stack.size < n
end

def run(nodes)
  nodes.each do |nd|
    case nd[0]
    when :num
      $stack << nd[1]
    when :def
      $defs[nd[1]] = nd[2]
    when :if
      need(1, "if")
      v = $stack.pop
      run(v != 0 ? nd[1] : nd[2])
    when :word
      w = nd[1]
      case w
      when "+", "-", "*", "=", "<", ">"
        need(2, w)
        b = $stack.pop
        a = $stack.pop
        $stack << case w
                  when "+" then a + b
                  when "-" then a - b
                  when "*" then a * b
                  when "=" then a == b ? 1 : 0
                  when "<" then a < b ? 1 : 0
                  else a > b ? 1 : 0
                  end
      when "/", "mod"
        need(2, w)
        raise LangError, "division by zero" if $stack[-1] == 0
        b = $stack.pop
        a = $stack.pop
        q = a.abs / b.abs
        q = -q if (a < 0) != (b < 0)
        $stack << (w == "/" ? q : a - q * b)
      when "dup"
        need(1, w)
        $stack << $stack[-1]
      when "drop"
        need(1, w)
        $stack.pop
      when "swap"
        need(2, w)
        $stack[-1], $stack[-2] = $stack[-2], $stack[-1]
      when "over"
        need(2, w)
        $stack << $stack[-2]
      when "."
        need(1, w)
        puts $stack.pop
      else
        body = $defs[w]
        raise LangError, "unknown word #{w}" if body.nil?
        raise LangError, "too deep" if $depth >= 100
        $depth += 1
        begin
          run(body)
        ensure
          $depth -= 1
        end
      end
    end
  end
end

$stdin.each_line.with_index(1) do |raw, no|
  toks = raw.chomp.split(" ")
  unless syntax_ok?(toks)
    puts "line #{no}: syntax error"
    next
  end
  saved = $stack.dup
  $depth = 0
  begin
    run(parse_seq(toks, [0]))
  rescue LangError => e
    $stack = saved
    puts "line #{no}: error: #{e.message}"
  end
end

puts($stack.empty? ? "stack: (empty)" : "stack: #{$stack.join(" ")}")

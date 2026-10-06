BUILTINS = %w[+ - * / mod = < > dup drop swap over . if else then : ;]

# Returns node list or nil on syntax error.
def parse(tokens)
  frames = [[:top, nil, []]] # [kind, info, nodes]
  i = 0
  while i < tokens.size
    t = tokens[i]
    top = frames.last
    case t
    when ":"
      return nil if frames.size > 1
      name = tokens[i + 1]
      return nil if name.nil? || name.match?(/\A-?\d+\z/) || BUILTINS.include?(name)
      frames << [:def, name, []]
      i += 1
    when ";"
      return nil unless top[0] == :def
      frames.pop
      frames.last[2] << [:def, top[1], top[2]]
    when "if"
      frames << [:if, { else: false, then_nodes: nil }, []]
    when "else"
      return nil unless top[0] == :if && !top[1][:else]
      top[1][:else] = true
      top[1][:then_nodes] = top[2]
      top[2] = []
    when "then"
      return nil unless top[0] == :if
      frames.pop
      if top[1][:else]
        frames.last[2] << [:if, top[1][:then_nodes], top[2]]
      else
        frames.last[2] << [:if, top[2], []]
      end
    else
      if t.match?(/\A-?\d+\z/)
        top[2] << [:num, t.to_i]
      else
        top[2] << [:word, t]
      end
    end
    i += 1
  end
  return nil unless frames.size == 1
  frames[0][2]
end

class RunError < StandardError; end

$stack = []
$dict = {}
$depth = 0
$lineno = 0

def need(n, w)
  raise RunError, "stack underflow in #{w}" if $stack.size < n
end

def run(nodes)
  nodes.each do |n|
    case n[0]
    when :num
      $stack.push(n[1])
    when :def
      $dict[n[1]] = n[2]
    when :if
      need(1, "if")
      v = $stack.pop
      run(v != 0 ? n[1] : n[2])
    when :word
      w = n[1]
      case w
      when "+", "-", "*", "=", "<", ">"
        need(2, w)
        b = $stack.pop
        a = $stack.pop
        $stack.push(
          case w
          when "+" then a + b
          when "-" then a - b
          when "*" then a * b
          when "=" then a == b ? 1 : 0
          when "<" then a < b ? 1 : 0
          else a > b ? 1 : 0
          end
        )
      when "/", "mod"
        need(2, w)
        b = $stack.pop
        a = $stack.pop
        raise RunError, "division by zero" if b == 0
        q = a.abs / b.abs
        q = -q if (a < 0) != (b < 0)
        $stack.push(w == "/" ? q : a - q * b)
      when "dup"
        need(1, w)
        $stack.push($stack.last)
      when "drop"
        need(1, w)
        $stack.pop
      when "swap"
        need(2, w)
        $stack[-1], $stack[-2] = $stack[-2], $stack[-1]
      when "over"
        need(2, w)
        $stack.push($stack[-2])
      when "."
        need(1, w)
        puts $stack.pop
      else
        body = $dict[w]
        raise RunError, "unknown word #{w}" if body.nil?
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
end

$stdin.each_line.with_index(1) do |raw, no|
  tokens = raw.chomp.split(" ")
  nodes = parse(tokens)
  if nodes.nil?
    puts "line #{no}: syntax error"
    next
  end
  saved = $stack.dup
  $depth = 0
  begin
    run(nodes)
  rescue RunError => e
    $stack = saved
    puts "line #{no}: error: #{e.message}"
  end
end

puts($stack.empty? ? "stack: (empty)" : "stack: #{$stack.join(" ")}")

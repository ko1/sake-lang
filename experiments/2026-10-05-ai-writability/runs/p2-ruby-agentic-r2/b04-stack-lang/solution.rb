BUILTINS = %w[+ - * / mod = < > dup drop swap over . if else then : ;]
NEED = {"+" => 2, "-" => 2, "*" => 2, "/" => 2, "mod" => 2, "=" => 2, "<" => 2, ">" => 2,
        "dup" => 1, "drop" => 1, "swap" => 2, "over" => 2, "." => 1}

class Syn < StandardError; end
class RunErr < StandardError; end

# Returns [nodes, next_index]; node: [:num, n] | [:word, w] | [:if, a, b] | [:def, name, body]
def parse(tk, i, ctx)
  nodes = []
  loop do
    t = tk[i]
    raise Syn if t.nil? && ctx != :top
    return [nodes, i, nil] if t.nil?
    i += 1
    case t
    when "if"
      a, i, stop = parse(tk, i, :then)
      b = []
      if stop == "else"
        b, i, stop = parse(tk, i, :else)
      end
      nodes << [:if, a, b]
    when "else"
      raise Syn unless ctx == :then
      return [nodes, i, "else"]
    when "then"
      raise Syn unless ctx == :then || ctx == :else
      return [nodes, i, "then"]
    when ";"
      raise Syn unless ctx == :def
      return [nodes, i, ";"]
    when ":"
      raise Syn unless ctx == :top
      name = tk[i]
      raise Syn if name.nil? || name =~ /\A-?\d+\z/ || BUILTINS.include?(name)
      body, i, = parse(tk, i + 1, :def)
      nodes << [:def, name, body]
    when /\A-?\d+\z/
      nodes << [:num, t.to_i]
    else
      nodes << [:word, t]
    end
  end
end

$stack = []
$dict = {}
$depth = 0

def need(w, n)
  raise RunErr, "stack underflow in #{w}" if $stack.size < n
end

def run(nodes)
  nodes.each do |n|
    case n[0]
    when :num then $stack.push(n[1])
    when :def then $dict[n[1]] = n[2]
    when :if
      need("if", 1)
      v = $stack.pop
      run(v != 0 ? n[1] : n[2])
    when :word
      w = n[1]
      if NEED.key?(w)
        need(w, NEED[w])
        case w
        when "+" then b = $stack.pop; $stack.push($stack.pop + b)
        when "-" then b = $stack.pop; $stack.push($stack.pop - b)
        when "*" then b = $stack.pop; $stack.push($stack.pop * b)
        when "/", "mod"
          b = $stack.pop
          a = $stack.pop
          if b == 0
            $stack.push(a, b)
            raise RunErr, "division by zero"
          end
          if w == "/"
            q = a.abs / b.abs
            q = -q if (a < 0) != (b < 0)
            $stack.push(q)
          else
            $stack.push(a.remainder(b))
          end
        when "=" then b = $stack.pop; $stack.push($stack.pop == b ? 1 : 0)
        when "<" then b = $stack.pop; $stack.push($stack.pop < b ? 1 : 0)
        when ">" then b = $stack.pop; $stack.push($stack.pop > b ? 1 : 0)
        when "dup" then $stack.push($stack.last)
        when "drop" then $stack.pop
        when "swap" then b = $stack.pop; a = $stack.pop; $stack.push(b, a)
        when "over" then $stack.push($stack[-2])
        when "." then puts $stack.pop
        end
      else
        body = $dict[w]
        raise RunErr, "unknown word #{w}" if body.nil?
        raise RunErr, "too deep" if $depth >= 100
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
  tk = raw.chomp.split(/ +/).reject(&:empty?)
  begin
    nodes, = parse(tk, 0, :top)
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
puts $stack.empty? ? "stack: (empty)" : "stack: #{$stack.join(" ")}"

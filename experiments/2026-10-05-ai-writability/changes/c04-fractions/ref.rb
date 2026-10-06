BUILTINS = %w[+ - * / mod = < > dup drop swap over . if else then : ;].freeze

class SyntaxErr < StandardError; end
class RunError < StandardError; end

def number?(t) = t.match?(%r{\A-?\d+(/\d+)?\z}) && !t.match?(%r{/0+\z})

def show(x) = x.denominator == 1 ? x.numerator.to_s : "#{x.numerator}/#{x.denominator}"

# Parses tokens from i until one of stops; returns [nodes, next index, stop token or nil].
def parse_seq(toks, i, stops, in_def)
  nodes = []
  while i < toks.size
    t = toks[i]
    return [nodes, i + 1, t] if stops.include?(t)
    case t
    when "if"
      yes, i, stop = parse_seq(toks, i + 1, %w[else then], in_def)
      raise SyntaxErr unless stop
      no = []
      if stop == "else"
        no, i, stop = parse_seq(toks, i, %w[then], in_def)
        raise SyntaxErr unless stop
      end
      nodes << [:if, yes, no]
    when ":"
      raise SyntaxErr if in_def || !stops.empty?
      name = toks[i + 1]
      raise SyntaxErr if name.nil? || number?(name) || BUILTINS.include?(name)
      body, i, stop = parse_seq(toks, i + 2, %w[;], true)
      raise SyntaxErr unless stop
      nodes << [:def, name, body]
    when "else", "then", ";"
      raise SyntaxErr
    else
      nodes << (number?(t) ? [:num, Rational(t)] : [:word, t])
      i += 1
    end
  end
  [nodes, i, nil]
end

class Machine
  def initialize
    @stack = []
    @words = {}
  end

  attr_reader :stack

  def pop(word)
    raise RunError, "stack underflow in #{word}" if @stack.empty?
    @stack.pop
  end

  def run_line(nodes)
    saved = @stack.dup
    run(nodes, 0)
  rescue RunError
    @stack = saved
    raise
  end

  def run(nodes, depth)
    nodes.each do |node|
      case node[0]
      when :num then @stack << node[1]
      when :def then @words[node[1]] = node[2]
      when :if
        run(pop("if") != 0 ? node[1] : node[2], depth)
      else
        word(node[1], depth)
      end
    end
  end

  def word(w, depth)
    case w
    when "+", "-", "*", "/", "mod", "=", "<", ">"
      raise RunError, "stack underflow in #{w}" if @stack.size < 2
      b = @stack.pop
      a = @stack.pop
      @stack << binop(w, a, b)
    when "dup" then x = pop(w); @stack.push(x, x)
    when "drop" then pop(w)
    when "swap", "over"
      raise RunError, "stack underflow in #{w}" if @stack.size < 2
      b = @stack.pop
      a = @stack.pop
      w == "swap" ? @stack.push(b, a) : @stack.push(a, b, a)
    when "." then puts show(pop(w))
    else
      body = @words[w] or raise RunError, "unknown word #{w}"
      raise RunError, "too deep" if depth >= 100
      run(body, depth + 1)
    end
  end

  def binop(w, a, b)
    case w
    when "+" then a + b
    when "-" then a - b
    when "*" then a * b
    when "=" then a == b ? 1r : 0r
    when "<" then a < b ? 1r : 0r
    when ">" then a > b ? 1r : 0r
    else
      raise RunError, "division by zero" if b == 0
      q = a / b
      w == "/" ? q : a - b * q.truncate
    end
  end
end

m = Machine.new
$stdin.each_line.with_index(1) do |line, lineno|
  begin
    nodes, = parse_seq(line.split, 0, [], false)
    m.run_line(nodes)
  rescue SyntaxErr
    puts "line #{lineno}: syntax error"
  rescue RunError => e
    puts "line #{lineno}: error: #{e.message}"
  end
end
puts "stack: #{m.stack.empty? ? "(empty)" : m.stack.map { show(_1) }.join(" ")}"

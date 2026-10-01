class Token
  attr_reader :kind, :text, :pos

  def initialize(kind, text, pos)
    @kind = kind
    @text = text
    @pos = pos
  end
end

class Num
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def to_s = @value.to_s
end

class Var
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def to_s = @name
end

class BinOp
  attr_reader :op, :left, :right

  def initialize(op, left, right)
    @op = op
    @left = left
    @right = right
  end

  def to_s = "(#{@left} #{@op} #{@right})"
end

class ParseError < StandardError
  attr_reader :pos

  def initialize(message, pos)
    super(message)
    @pos = pos
  end
end

class EvalError < StandardError
end

def tokenize(src)
  tokens = []
  i = 0
  n = src.size
  while i < n
    c = src[i]
    if c == " "
      i += 1
    elsif c.match?(/\d/)
      j = i
      j += 1 while j < n && src[j].match?(/\d/)
      tokens << Token.new(:num, src[i...j], i)
      i = j
    elsif c.match?(/[a-z]/)
      j = i
      j += 1 while j < n && src[j].match?(/[a-z0-9_]/)
      tokens << Token.new(:ident, src[i...j], i)
      i = j
    elsif "+-*/%^()".include?(c)
      tokens << Token.new(:op, c, i)
      i += 1
    else
      raise ParseError.new("unexpected character '#{c}'", i)
    end
  end
  tokens << Token.new(:eof, "end of input", n)
  tokens
end

class Parser
  attr_reader :tokens
  attr_accessor :pos

  def initialize(tokens, pos)
    @tokens = tokens
    @pos = pos
  end

  def peek = @tokens.fetch(@pos)

  def advance
    t = peek
    @pos += 1 if t.kind != :eof
    t
  end

  def op?(ops)
    t = peek
    t.kind == :op && ops.include?(t.text)
  end

  def expect(text)
    t = advance
    if t.text != text
      raise ParseError.new("expected '#{text}' but got '#{t.text}'", t.pos)
    end
    t
  end

  def parse
    tree = parse_expr
    t = peek
    if t.kind != :eof
      raise ParseError.new("unexpected '#{t.text}'", t.pos)
    end
    tree
  end

  def parse_expr
    left = parse_term
    while op?(["+", "-"])
      op = advance.text
      left = BinOp.new(op, left, parse_term)
    end
    left
  end

  def parse_term
    left = parse_unary
    while op?(["*", "/", "%"])
      op = advance.text
      left = BinOp.new(op, left, parse_unary)
    end
    left
  end

  def parse_unary
    if op?(["-"])
      advance
      return BinOp.new("-", Num.new(0), parse_unary)
    end
    parse_power
  end

  def parse_power
    base = parse_atom
    if op?(["^"])
      advance
      return BinOp.new("^", base, parse_unary)
    end
    base
  end

  def parse_atom
    t = advance
    text = t.text
    case t.kind
    when :num then Num.new(text.to_i)
    when :ident then Var.new(text)
    else
      if text == "("
        inner = parse_expr
        expect(")")
        inner
      else
        raise ParseError.new("unexpected '#{text}'", t.pos)
      end
    end
  end
end

def evaluate(node, env)
  case node
  when Num then node.value
  when Var
    name = node.name
    v = env[name]
    raise EvalError, "undefined variable '#{name}'" if v.nil?
    v
  when BinOp
    l = evaluate(node.left, env)
    r = evaluate(node.right, env)
    op = node.op
    if op == "+"
      l + r
    elsif op == "-"
      l - r
    elsif op == "*"
      l * r
    elsif op == "^"
      raise EvalError, "negative exponent #{r}" if r < 0
      l ** r
    else
      raise EvalError, "division by zero in #{node}" if r == 0
      op == "/" ? l / r : l % r
    end
  end
end

def count_nodes(node)
  case node
  when BinOp then 1 + count_nodes(node.left) + count_nodes(node.right)
  else 1
  end
end

env = { "x" => 3, "y" => 4, "rate" => 7 }
sources = [
  "1 + 2 * 3", "(1 + 2) * 3", "2 ^ 3 ^ 2", "x * x + y * y", "-x + 10",
  "rate * (x - -y) % 5", "10 / (y - 4)", "z + 1", "3 + * 4", "7 $ 2",
  "(1 + 2", "2 ^ -1", "100 / 7 / 2"
]
ok = 0
sources.each do |src|
  begin
    ps = Parser.new(tokenize(src), 0)
    tree = ps.parse
    value = evaluate(tree, env)
    ok += 1
    puts format("%-22s => %-30s = %d  [%d nodes]", src, tree, value, count_nodes(tree))
  rescue ParseError => e
    puts format("%-22s !! parse error at %d: %s", src, e.pos, e.message)
    puts "    #{src}"
    puts "    #{" " * e.pos}^"
  rescue EvalError => e
    puts format("%-22s !! eval error: %s", src, e.message)
  end
end
puts "#{ok}/#{sources.size} evaluated"

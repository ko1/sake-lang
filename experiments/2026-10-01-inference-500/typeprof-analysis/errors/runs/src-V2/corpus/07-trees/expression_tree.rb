class Num
  attr_reader :value

  def initialize(value)
    @value = value
  end
end

class Var
  attr_reader :name

  def initialize(name)
    @name = name
  end
end

class BinOp
  attr_reader :op, :left, :right

  def initialize(op, left, right)
    @op = op
    @left = left
    @right = right
  end
end

class ParseError < StandardError
  attr_reader :pos

  def initialize(message, pos)
    super(message)
    @pos = pos
  end
end

class UnboundError < StandardError
  attr_reader :name

  def initialize(message, name)
    super(message)
    @name = name
  end
end

class Parser
  def self.parse(src)
    ps = new(src.scan(%r{\d+(?:\.\d+)?|[a-z]+|[-+*/^()]}))
    e = ps.expr
    raise ParseError.new("trailing #{ps.peek}", ps.pos) unless ps.peek.nil?
    e
  end

  attr_reader :pos

  def initialize(tokens)
    @tokens = tokens
    @pos = 0
  end

  def peek = @tokens[@pos]

  def advance
    t = @tokens[@pos]
    @pos += 1
    t
  end

  def expect(t)
    got = advance
    raise ParseError.new("expected #{t} but got #{got.nil? ? "end" : got}", @pos) unless got == t
  end

  def expr
    left = term
    while peek == "+" || peek == "-"
      op = advance
      left = BinOp.new(op, left, term)
    end
    left
  end

  def term
    left = power
    while peek == "*" || peek == "/"
      op = advance
      left = BinOp.new(op, left, power)
    end
    left
  end

  def power
    base = atom
    if peek == "^"
      advance
      return BinOp.new("^", base, power)
    end
    base
  end

  def atom
    t = advance
    raise ParseError.new("unexpected end", @pos) if t.nil?
    if t == "("
      e = expr
      expect(")")
      e
    elsif t == "-"
      BinOp.new("-", Num.new(0), atom)
    elsif t.match?(/\A\d/)
      t.include?(".") ? Num.new(t.to_f) : Num.new(t.to_i)
    elsif t.match?(/\A[a-z]/)
      Var.new(t)
    else
      raise ParseError.new("unexpected #{t}", @pos)
    end
  end
end

def evaluate(e, env)
  case e
  when Num then e.value
  when Var
    v = env[e.name]
    raise UnboundError.new("unbound variable #{e.name}", e.name) if v.nil?
    v
  when BinOp
    a = evaluate(e.left, env)
    b = evaluate(e.right, env)
    case e.op
    when "+" then a + b
    when "-" then a - b
    when "*" then a * b
    when "/" then a / b
    else a**b
    end
  end
end

def prec(op)
  case op
  when "+", "-" then 1
  when "*", "/" then 2
  else 3
  end
end

def show(e)
  case e
  when Num then e.value.to_s
  when Var then e.name
  when BinOp
    op = e.op
    l = e.left
    r = e.right
    ls = show(l)
    rs = show(r)
    ls = "(#{ls})" if l.is_a?(BinOp) && prec(l.op) < prec(op)
    rs = "(#{rs})" if r.is_a?(BinOp) && (prec(r.op) < prec(op) || (prec(r.op) == prec(op) && op != "^"))
    "#{ls} #{op} #{rs}"
  end
end

def num?(e, v) = e.is_a?(Num) && e.value == v

def simplify(e)
  return e unless e.is_a?(BinOp)
  op = e.op
  l = simplify(e.left)
  r = simplify(e.right)
  if l.is_a?(Num) && r.is_a?(Num) && (op != "/" || r.value != 0)
    return Num.new(evaluate(BinOp.new(op, l, r), {}))
  end
  return r if op == "+" && num?(l, 0)
  return l if (op == "+" || op == "-") && num?(r, 0)
  return Num.new(0) if op == "*" && (num?(l, 0) || num?(r, 0))
  return r if op == "*" && num?(l, 1)
  return l if %w[* / ^].include?(op) && num?(r, 1)
  return Num.new(1) if op == "^" && num?(r, 0)
  BinOp.new(op, l, r)
end

def derive(e, x)
  case e
  when Num then Num.new(0)
  when Var then Num.new(e.name == x ? 1 : 0)
  when BinOp
    u = e.left
    v = e.right
    du = derive(u, x)
    dv = derive(v, x)
    case e.op
    when "+", "-" then BinOp.new(e.op, du, dv)
    when "*" then BinOp.new("+", BinOp.new("*", du, v), BinOp.new("*", u, dv))
    when "/"
      BinOp.new("/", BinOp.new("-", BinOp.new("*", du, v), BinOp.new("*", u, dv)), BinOp.new("^", v, Num.new(2)))
    else
      raise ArgumentError, "cannot differentiate non-constant power" unless v.is_a?(Num)
      BinOp.new("*", BinOp.new("*", v, BinOp.new("^", u, Num.new(v.value - 1))), du)
    end
  end
end

def node_count(e) = e.is_a?(BinOp) ? 1 + node_count(e.left) + node_count(e.right) : 1

env = { "x" => 3, "y" => 2.5, "n" => 4 }
sources = ["1 + 2 * 3", "(1 + 2) * 3", "2 ^ 3 ^ 2", "x * x - 4 * x + 4", "10 - 4 - 3", "8 / (4 / 2)",
           "y * (x + 1) / 2", "-x + n * 0 + 1 * y", "x ^ n / (x - 3 + 0)", "2 * (3 + ", "z + 1", "4 $ 2"]
sources.each do |src|
  tree = Parser.parse(src)
  simp = simplify(tree)
  puts "#{src}  =>  #{show(tree)}  [#{node_count(tree)} nodes]"
  puts "    simplified: #{show(simp)}  [#{node_count(simp)} nodes]" if node_count(simp) < node_count(tree)
  puts "    value: #{evaluate(tree, env)}"
rescue ParseError => e
  puts "#{src}  =>  parse error at #{e.pos}: #{e.message}"
rescue UnboundError => e
  puts "    error: #{e.message}"
rescue ZeroDivisionError
  puts "    error: division by zero"
end

puts "-- derivatives d/dx --"
["x * x - 4 * x + 4", "3 * x ^ 3 + y * x", "x / (x + 1)", "2 ^ x"].each do |src|
  d = simplify(derive(Parser.parse(src), "x"))
  puts "#{src}  ->  #{show(d)}  = #{evaluate(d, env)} at x=3"
rescue ArgumentError => e
  puts "#{src}  ->  #{e.message}"
end

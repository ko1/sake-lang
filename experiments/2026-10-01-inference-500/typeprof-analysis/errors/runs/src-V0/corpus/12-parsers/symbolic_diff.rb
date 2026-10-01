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

class Bin
  attr_reader :op, :left, :right

  def initialize(op, left, right)
    @op = op
    @left = left
    @right = right
  end
end

class Fn
  attr_reader :name, :arg

  def initialize(name, arg)
    @name = name
    @arg = arg
  end
end

class ParseError < StandardError
  attr_reader :pos

  def initialize(message, pos)
    super(message)
    @pos = pos
  end
end

class Parser
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
    raise ParseError.new("expected #{t}", @pos) unless peek == t
    advance
  end

  def expr
    e = term
    e = Bin.new(advance, e, term) while peek == "+" || peek == "-"
    e
  end

  def term
    e = unary
    e = Bin.new(advance, e, unary) while peek == "*" || peek == "/"
    e
  end

  def unary
    if peek == "-"
      advance
      return Bin.new("*", Num.new(-1), unary)
    end
    power
  end

  def power
    base = primary
    if peek == "^"
      advance
      return Bin.new("^", base, unary)
    end
    base
  end

  def primary
    t = advance
    raise ParseError.new("unexpected end", @pos) if t.nil?
    case t
    when "("
      e = expr
      expect(")")
      e
    when /\A\d+\z/ then Num.new(t.to_i)
    when /\A\d+\.\d+\z/ then Num.new(t.to_f)
    when "sin", "cos", "exp", "ln"
      expect("(")
      e = expr
      expect(")")
      Fn.new(t, e)
    when /\A[a-z]\z/ then Var.new(t)
    else raise ParseError.new("unexpected '#{t}'", @pos - 1)
    end
  end
end

def parse(src)
  ps = Parser.new(src.scan(/\d+\.\d+|\d+|[a-z]+|\S/))
  e = ps.expr
  raise ParseError.new("trailing '#{ps.peek}'", ps.pos) if ps.peek
  e
end

def num?(e, v) = e.is_a?(Num) && e.value == v

def add(a, b)
  return b if num?(a, 0)
  return a if num?(b, 0)
  return Num.new(a.value + b.value) if a.is_a?(Num) && b.is_a?(Num)
  Bin.new("+", a, b)
end

def sub(a, b)
  return a if num?(b, 0)
  return Num.new(a.value - b.value) if a.is_a?(Num) && b.is_a?(Num)
  Bin.new("-", a, b)
end

def mul(a, b)
  return Num.new(0) if num?(a, 0) || num?(b, 0)
  return b if num?(a, 1)
  return a if num?(b, 1)
  return Num.new(a.value * b.value) if a.is_a?(Num) && b.is_a?(Num)
  Bin.new("*", a, b)
end

def div(a, b)
  return a if num?(b, 1)
  return Num.new(0) if num?(a, 0)
  Bin.new("/", a, b)
end

def pow(a, b)
  return Num.new(1) if num?(b, 0)
  return a if num?(b, 1)
  Bin.new("^", a, b)
end

def derive(e, x)
  case e
  when Num then Num.new(0)
  when Var then Num.new(e.name == x ? 1 : 0)
  when Fn
    u = e.arg
    du = derive(u, x)
    case e.name
    when "sin" then mul(Fn.new("cos", u), du)
    when "cos" then mul(mul(Num.new(-1), Fn.new("sin", u)), du)
    when "exp" then mul(e, du)
    when "ln" then div(du, u)
    end
  when Bin
    l = e.left
    r = e.right
    dl = derive(l, x)
    dr = derive(r, x)
    case e.op
    when "+" then add(dl, dr)
    when "-" then sub(dl, dr)
    when "*" then add(mul(dl, r), mul(l, dr))
    when "/" then div(sub(mul(dl, r), mul(l, dr)), pow(r, Num.new(2)))
    when "^"
      if r.is_a?(Num)
        mul(mul(r, pow(l, Num.new(r.value - 1))), dl)
      else
        mul(e, add(mul(dr, Fn.new("ln", l)), div(mul(r, dl), l)))
      end
    end
  end
end

PREC = { "+" => 1, "-" => 1, "*" => 2, "/" => 2, "^" => 3 }.freeze

def show(e, outer)
  case e
  when Num
    s = e.value.to_s
    e.value < 0 && outer > 0 ? "(#{s})" : s
  when Var then e.name
  when Fn then "#{e.name}(#{show(e.arg, 0)})"
  when Bin
    op = e.op
    p = PREC[op]
    left = show(e.left, op == "^" ? p + 1 : p)
    right = show(e.right, op == "^" ? p : p + 1)
    s = op == "^" ? "#{left}^#{right}" : "#{left} #{op} #{right}"
    p < outer ? "(#{s})" : s
  end
end

def evaluate(e, env)
  case e
  when Num then e.value
  when Var then env[e.name]
  when Fn
    v = evaluate(e.arg, env)
    case e.name
    when "sin" then Math.sin(v)
    when "cos" then Math.cos(v)
    when "exp" then Math.exp(v)
    when "ln" then Math.log(v)
    end
  when Bin
    a = evaluate(e.left, env)
    b = evaluate(e.right, env)
    case e.op
    when "+" then a + b
    when "-" then a - b
    when "*" then a * b
    when "/" then a / b
    when "^" then a**b
    end
  end
end

inputs = ["x^3 + 2*x", "sin(x) * x", "exp(2*x) / x", "ln(x^2 + 1)", "3 * y + x * y",
          "-x^2", "x^x", "(1 + x) * (1 - x)", "cos(sin(x))", "2 * (x + ", "x $ 2", "sqrt(x)"]
x0 = 1.5
h = 0.000001
inputs.each do |src|
  f = parse(src)
  df = derive(f, "x")
  exact = evaluate(df, { "x" => x0, "y" => 2.0 }).round(4)
  numeric = ((evaluate(f, { "x" => x0 + h, "y" => 2.0 }) - evaluate(f, { "x" => x0 - h, "y" => 2.0 })) / (2 * h)).round(4)
  puts "f(x)  = #{show(f, 0)}"
  puts "f'(x) = #{show(df, 0)}"
  puts "f'(#{x0}) = #{exact} (numeric #{numeric})#{(exact - numeric).abs < 0.001 ? "" : " MISMATCH"}"
rescue ParseError => e
  puts "#{src}: parse error at token #{e.pos}: #{e.message}"
end

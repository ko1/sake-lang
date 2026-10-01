class Node
  attr_reader :kind, :value, :kids

  def initialize(kind, value, kids)
    @kind = kind
    @value = value
    @kids = kids
  end
end

class ParseError < StandardError
  attr_reader :token

  def initialize(message, token)
    super(message)
    @token = token
  end
end

class EvalError < StandardError
end

INFIX = {
  "or" => [1, 2], "and" => [3, 4],
  "==" => [7, 8], "!=" => [7, 8],
  "<" => [9, 10], ">" => [9, 10], "<=" => [9, 10], ">=" => [9, 10],
  "+" => [11, 12], "-" => [11, 12],
  "*" => [13, 14], "/" => [13, 14], "%" => [13, 14],
  "^" => [16, 15]
}.freeze

class Parser
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
    raise ParseError.new("expected '#{t}'", got || "end") unless got == t
  end

  def list_until(close)
    items = []
    if peek == close
      advance
      return items
    end
    loop do
      items << expr(0)
      t = advance
      return items if t == close
      raise ParseError.new("expected ',' or '#{close}'", t || "end") unless t == ","
    end
  end

  def nud(t)
    raise ParseError.new("unexpected end", "end") if !t    
    case t
    when /\A\d+\z/ then Node.new(:num, t.to_i, [])
    when "true", "false" then Node.new(:bool, t == "true", [])
    when "-" then Node.new(:neg, nil, [expr(90)])
    when "not" then Node.new(:not, nil, [expr(5)])
    when "("
      e = expr(0)
      expect(")")
      e
    when "[" then Node.new(:list, nil, list_until("]"))
    when /\A[A-Za-z_]\w*\z/ then Node.new(:var, t, [])
    else raise ParseError.new("unexpected token", t)
    end
  end

  def expr(min_bp)
    lhs = nud(advance)
    while (op = peek)
      if op == "(" || op == "["
        break if 100 < min_bp
        advance
        if op == "("
          lhs = Node.new(:call, nil, [lhs, *list_until(")")])
        else
          index = expr(0)
          expect("]")
          lhs = Node.new(:index, nil, [lhs, index])
        end
      elsif op == "?"
        break if 5 < min_bp
        advance
        yes = expr(0)
        expect(":")
        no = expr(4)
        lhs = Node.new(:cond, nil, [lhs, yes, no])
      elsif INFIX.key?(op)
        lbp, rbp = INFIX[op]
        break if lbp < min_bp
        advance
        lhs = Node.new(:bin, op, [lhs, expr(rbp)])
      else
        break
      end
    end
    lhs
  end
end

def parse(src)
  ps = Parser.new(src.scan(/\d+|[A-Za-z_]\w*|==|!=|<=|>=|\S/))
  e = ps.expr(0)
  rest = ps.peek
  raise ParseError.new("unexpected token", rest) if rest
  e
end

def sexpr(n)
  kids = n.kids.map { |k| sexpr(k) }
  case n.kind
  when :num, :var then n.value.to_s
  when :bool then n.value ? "#t" : "#f"
  when :list then "[#{kids.join(" ")}]"
  when :bin then "(#{n.value} #{kids.join(" ")})"
  else "(#{n.kind} #{kids.join(" ")})"
  end
end

def size(n) = 1 + n.kids.sum { |k| size(k) }

def int!(v, what)
  raise EvalError, "#{what} needs an integer, got #{v.inspect}" unless v.is_a?(Integer)
  v
end

def bool!(v, what)
  raise EvalError, "#{what} needs a boolean, got #{v.inspect}" unless v == true || v == false
  v
end

def call_builtin(name, args)
  case name
  when "max" then args.map { |a| int!(a, "max") }.max
  when "min" then args.map { |a| int!(a, "min") }.min
  when "len"
    raise EvalError, "len needs a list" unless args[0].is_a?(Array)
    args[0].size
  when "sum"
    raise EvalError, "sum needs a list" unless args[0].is_a?(Array)
    args[0].sum { |x| int!(x, "sum") }
  else raise EvalError, "unknown function #{name}"
  end
end

def evaluate(n, env)
  kids = n.kids
  case n.kind
  when :num, :bool then n.value
  when :var
    raise EvalError, "undefined variable #{n.value}" unless env.key?(n.value)
    env[n.value]
  when :list then kids.map { |k| evaluate(k, env) }
  when :neg then -int!(evaluate(kids[0], env), "-")
  when :not then !bool!(evaluate(kids[0], env), "not")
  when :cond then bool!(evaluate(kids[0], env), "?:") ? evaluate(kids[1], env) : evaluate(kids[2], env)
  when :index
    list = evaluate(kids[0], env)
    raise EvalError, "only lists can be indexed" unless list.is_a?(Array)
    v = list[int!(evaluate(kids[1], env), "index")]
    raise EvalError, "index out of range" if !v    
    v
  when :call
    f = kids[0]
    raise EvalError, "only named functions can be called" unless f.kind == :var
    call_builtin(f.value, kids.drop(1).map { |k| evaluate(k, env) })
  when :bin
    op = n.value
    if op == "and" || op == "or"
      left = bool!(evaluate(kids[0], env), op)
      return left if (op == "and" && !left) || (op == "or" && left)
      return bool!(evaluate(kids[1], env), op)
    end
    a = evaluate(kids[0], env)
    b = evaluate(kids[1], env)
    return op == "==" ? a == b : a != b if op == "==" || op == "!="
    a = int!(a, op)
    b = int!(b, op)
    case op
    when "+" then a + b
    when "-" then a - b
    when "*" then a * b
    when "/", "%"
      raise EvalError, "division by zero" if b == 0
      op == "/" ? a / b : a % b
    when "^" then a**b
    when "<" then a < b
    when ">" then a > b
    when "<=" then a <= b
    when ">=" then a >= b
    end
  end
end

def show(v) = v.is_a?(Array) ? "[" + v.map { |x| show(x) }.join(", ") + "]" : v.to_s

env = { "x" => 3, "y" => 4, "xs" => [5, 1, 4], "ok" => true }
sources = [
  "1 + 2 * 3 - 4",
  "2 ^ 3 ^ 2",
  "-x ^ 2 + y",
  "(x + y) * (x - y) % 5",
  "x < y and not ok or y == 4",
  "x > 2 ? xs[0] : xs[1] + 100",
  "max(x, y, 10 - x) * len(xs)",
  "sum([x, y, x * y]) / 2",
  "ok ? 1 : 0 ? 2 : 3",
  "xs[1 + 1] - xs[-1 + 1]",
  "x + ok",
  "xs[7]",
  "10 / (y - 4)",
  "nope(1)",
  "(1 + 2",
  "1 + * 2",
  "[1, 2 3]"
]
sources.each do |src|
  tree = parse(src)
  line = "#{sexpr(tree)}  [#{size(tree)} nodes]"
  begin
    line += " => #{show(evaluate(tree, env))}"
  rescue EvalError => e
    line += " => error: #{e.message}"
  end
  puts "#{src}\n    #{line}"
rescue ParseError => e
  puts "#{src}\n    parse error: #{e.message} at '#{e.token}'"
end

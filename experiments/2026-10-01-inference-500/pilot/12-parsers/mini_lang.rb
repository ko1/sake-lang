class LangError < StandardError
end

class ReturnSignal < StandardError
  attr_reader :value

  def initialize(message, value)
    super(message)
    @value = value
  end
end

class Frame
  attr_reader :vars, :funcs, :out, :depth

  def initialize(vars, funcs, out, depth)
    @vars = vars
    @funcs = funcs
    @out = out
    @depth = depth
  end
end

module Node
  def run(fr) = raise(LangError, "cannot run #{self}")
end

def precedence = [["<", ">", "==", "!="], ["+", "-"], ["*", "/", "%"]]

def run_all(stmts, fr) = stmts.each { |s| s.run(fr) }

class Lit
  include Node
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def run(fr) = @value
end

class Ref
  include Node
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def run(fr)
    v = fr.vars[@name]
    raise LangError, "undefined variable '#{@name}'" if v.nil?
    v
  end
end

class Bin
  include Node
  attr_reader :op, :left, :right

  def initialize(op, left, right)
    @op = op
    @left = left
    @right = right
  end

  def run(fr)
    a = @left.run(fr)
    b = @right.run(fr)
    case @op
    when "+" then a + b
    when "-" then a - b
    when "*" then a * b
    when "/", "%"
      raise LangError, "division by zero" if b == 0
      @op == "/" ? a / b : a % b
    when "<" then a < b ? 1 : 0
    when ">" then a > b ? 1 : 0
    when "==" then a == b ? 1 : 0
    else a != b ? 1 : 0
    end
  end
end

class Call
  include Node
  attr_reader :name, :args

  def initialize(name, args)
    @name = name
    @args = args
  end

  def run(fr)
    f = fr.funcs[@name]
    raise LangError, "undefined function '#{@name}'" if f.nil?
    params = f.params
    want = params.size
    raise LangError, "#{@name} expects #{want} argument(s), got #{@args.size}" if want != @args.size
    raise LangError, "call depth exceeded in #{@name}" if fr.depth >= 200
    vars = {}
    params.zip(@args).each { |p, e| vars[p] = e.run(fr) }
    callee = Frame.new(vars, fr.funcs, fr.out, fr.depth + 1)
    begin
      run_all(f.body, callee)
      0
    rescue ReturnSignal => r
      r.value
    end
  end
end

class Assign
  include Node
  attr_reader :name, :expr

  def initialize(name, expr)
    @name = name
    @expr = expr
  end

  def run(fr) = fr.vars[@name] = @expr.run(fr)
end

class Print
  include Node
  attr_reader :exprs

  def initialize(exprs)
    @exprs = exprs
  end

  def run(fr) = fr.out.push(@exprs.map { it.run(fr) }.join(" "))
end

class If
  include Node
  attr_reader :cond, :then_body, :else_body

  def initialize(cond, then_body, else_body)
    @cond = cond
    @then_body = then_body
    @else_body = else_body
  end

  def run(fr) = @cond.run(fr) != 0 ? run_all(@then_body, fr) : run_all(@else_body, fr)
end

class FunDef
  include Node
  attr_reader :name, :params, :body

  def initialize(name, params, body)
    @name = name
    @params = params
    @body = body
  end

  def run(fr) = fr.funcs[@name] = self
end

class Return
  include Node
  attr_reader :expr

  def initialize(expr)
    @expr = expr
  end

  def run(fr) = raise(ReturnSignal.new("return", @expr.run(fr)))
end

class Parser
  attr_reader :tokens
  attr_accessor :pos

  def initialize(tokens, pos)
    @tokens = tokens
    @pos = pos
  end

  def peek = @tokens[@pos]

  def take
    t = @tokens[@pos]
    raise LangError, "unexpected end of program" if t.nil?
    @pos += 1
    t
  end

  def accept(tok)
    return false if peek != tok
    @pos += 1
    true
  end

  def expect(tok)
    t = take
    raise LangError, "expected '#{tok}' but found '#{t}'" if t != tok
  end

  def ident
    t = take
    raise LangError, "expected a name but found '#{t}'" unless t.match?(/\A[a-z_]\w*\z/)
    t
  end

  def comma_list
    items = []
    return items if accept(")")
    items << yield
    items << yield while accept(",")
    expect(")")
    items
  end

  def block
    stmts = []
    stmts << statement until [nil, "end", "else"].include?(peek)
    stmts
  end

  def statement
    if accept("print")
      exprs = [expr]
      exprs << expr while accept(",")
      Print.new(exprs)
    elsif accept("if")
      cond = expr
      expect("then")
      then_body = block
      else_body = accept("else") ? block : []
      expect("end")
      If.new(cond, then_body, else_body)
    elsif accept("fun")
      name = ident
      expect("(")
      params = comma_list { ident }
      body = block
      expect("end")
      FunDef.new(name, params, body)
    elsif accept("return")
      Return.new(expr)
    else
      name = ident
      expect("=")
      Assign.new(name, expr)
    end
  end

  def expr = binary(0)

  def binary(level)
    return atom if level == precedence.size
    left = binary(level + 1)
    while precedence[level].include?(peek)
      op = take
      left = Bin.new(op, left, binary(level + 1))
    end
    left
  end

  def atom
    t = take
    return Lit.new(t.to_i) if t.match?(/\A\d+\z/)
    if t == "("
      e = expr
      expect(")")
      return e
    end
    @pos -= 1
    name = ident
    return Ref.new(name) unless accept("(")
    Call.new(name, comma_list { expr })
  end
end

def interpret(source)
  clean = source.gsub(/#[^\n]*/, "")
  tokens = clean.scan(/\d+|[a-z_]\w*|==|!=|[-+*\/%<>=(),]|\S/)
  ps = Parser.new(tokens, 0)
  program = ps.block
  raise LangError, "unexpected '#{ps.peek}'" if ps.peek != nil
  fr = Frame.new({}, {}, [], 0)
  run_all(program, fr)
  fr.out
end

programs = {
  "fib" => "fun fib(n)\n  if n < 2 then return n end\n  return fib(n - 1) + fib(n - 2)\nend\nfun show(i, n)\n  if i < n then print i, fib(i)  rest = show(i + 1, n) end\nend\nx = show(0, 8)",
  "functions" => "fun fact(n)\n  if n < 2 then return 1 end\n  return n * fact(n - 1)\nend\nfun gcd(a, b)\n  if b == 0 then return a else return gcd(b, a % b) end\nend\nprint fact(12), gcd(1071, 462)\nprint gcd(fact(6), 84)",
  "collatz" => "# length of Collatz chains\nfun steps(n)\n  if n == 1 then return 0 end\n  if n % 2 == 0 then next = n / 2 else next = 3 * n + 1 end\n  return 1 + steps(next)\nend\nprint steps(6), steps(27), steps(97)",
  "undefined" => "x = 1\nprint x + y",
  "arity" => "fun add(a, b) return a + b end\nprint add(1)",
  "runaway" => "fun f(n) return f(n + 1) end\nprint f(0)",
  "syntax" => "if 1 then print 2",
  "divide" => "fun half(n) return n / (n - n) end\nprint half(8)"
}

programs.each do |name, source|
  begin
    out = interpret(source)
    puts "#{name}: #{out.size} line(s)"
    out.each { |line| puts "  | #{line}" }
  rescue LangError => e
    puts "#{name}: error: #{e.message}"
  end
end

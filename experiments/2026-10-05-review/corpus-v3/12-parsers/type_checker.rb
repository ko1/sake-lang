class SyntaxErr < StandardError
  attr_reader :token

  def initialize(message, token)
    super(message)
    @token = token
  end
end

class TypeErr < StandardError
end

KEYWORDS = %w[let in if then else].freeze

class Stream
  def initialize(tokens)
    @tokens = tokens
    @pos = 0
  end

  def peek = @tokens[@pos]

  def take
    t = @tokens[@pos]
    raise SyntaxErr.new("unexpected end of input", "end") if t.nil?
    @pos += 1
    t
  end

  def expect(want)
    t = take
    raise SyntaxErr.new("expected '#{want}'", t) unless t == want
  end

  def expr
    case peek
    when "let"
      take
      name = take
      raise SyntaxErr.new("expected a name", name) unless name.match?(/\A[a-z_]\w*\z/)
      expect("=")
      value = expr
      expect("in")
      [:let, name, value, expr]
    when "if"
      take
      c = expr
      expect("then")
      a = expr
      expect("else")
      [:if, c, a, expr]
    else
      compare
    end
  end

  def compare
    left = concat
    return [:bin, take, left, concat] if peek == "==" || peek == "<"
    left
  end

  def concat
    left = additive
    left = [:bin, take, left, additive] while peek == "++"
    left
  end

  def additive
    left = term
    left = [:bin, take, left, term] while peek == "+" || peek == "-"
    left
  end

  def term
    left = atom
    left = [:bin, take, left, atom] while peek == "*"
    left
  end

  def atom
    t = take
    if t == "("
      e = expr
      expect(")")
      e
    elsif t.match?(/\A\d+\z/)
      [:lit, t.to_i]
    elsif t.start_with?("\"")
      [:lit, t[1...-1]]
    elsif t == "true" || t == "false"
      [:lit, t == "true"]
    elsif t.match?(/\A[a-z_]\w*\z/) && !KEYWORDS.include?(t)
      if peek == "("
        take
        arg = expr
        expect(")")
        return [:call, t, arg]
      end
      [:var, t]
    else
      raise SyntaxErr.new("unexpected token", t)
    end
  end
end

def parse(src)
  s = Stream.new(src.scan(/"[^"]*"|\d+|[a-z_]\w*|\+\+|==|\S/))
  e = s.expr
  raise SyntaxErr.new("unexpected token", s.peek) if s.peek
  e
end

BUILTINS = { "len" => [:str, :int], "show" => [:int, :str], "not" => [:bool, :bool], "upcase" => [:str, :str] }.freeze

def type_of_value(v)
  case v
  when Integer then :int
  when String then :str
  when true, false then :bool
  end
end

def check(e, env)
  case e
  in [:lit, v] then type_of_value(v)
  in [:var, name]
    env.fetch(name) { raise TypeErr, "unbound variable #{name}" }
  in [:let, name, value, body] then check(body, env.merge(name => check(value, env)))
  in [:if, cond, yes, no]
    c = check(cond, env)
    raise TypeErr, "condition must be bool, got #{c}" unless c == :bool
    a = check(yes, env)
    b = check(no, env)
    raise TypeErr, "branches differ: #{a} vs #{b}" unless a == b
    a
  in [:call, fn, arg_expr]
    sig = BUILTINS[fn]
    raise TypeErr, "unknown function #{fn}" if sig.nil?
    param, result = sig
    arg = check(arg_expr, env)
    raise TypeErr, "#{fn} expects #{param}, got #{arg}" unless arg == param
    result
  in [:bin, op, lhs, rhs]
    l = check(lhs, env)
    r = check(rhs, env)
    case op
    when "+", "-", "*"
      raise TypeErr, "'#{op}' needs int operands, got #{l} and #{r}" unless l == :int && r == :int
      :int
    when "++"
      raise TypeErr, "'++' needs str operands, got #{l} and #{r}" unless l == :str && r == :str
      :str
    when "<"
      raise TypeErr, "'<' needs int operands, got #{l} and #{r}" unless l == :int && r == :int
      :bool
    when "=="
      raise TypeErr, "'==' compares #{l} with #{r}" unless l == r
      :bool
    end
  end
end

def evaluate(e, env)
  case e
  in [:lit, v] then v
  in [:var, name] then env[name]
  in [:let, name, value, body] then evaluate(body, env.merge(name => evaluate(value, env)))
  in [:if, cond, yes, no] then evaluate(cond, env) ? evaluate(yes, env) : evaluate(no, env)
  in [:call, fn, arg]
    v = evaluate(arg, env)
    case fn
    when "len" then v.size
    when "show" then v.to_s
    when "not" then !v
    when "upcase" then v.upcase
    end
  in [:bin, op, lhs, rhs]
    a = evaluate(lhs, env)
    b = evaluate(rhs, env)
    op == "++" ? a + b : a.public_send(op, b)
  end
end

def show_value(v) = v.is_a?(String) ? v.inspect : v.to_s

programs = [
  "1 + 2 * 3",
  "let x = 5 in let y = x * x in y - x",
  "\"ab\" ++ show(len(\"hello\") + 1)",
  "if len(\"abc\") < 4 then upcase(\"short\") else \"long\"",
  "let ok = not(1 == 2) in if ok then 10 else 20",
  "let s = \"x\" in s == \"x\"",
  "1 + \"two\"",
  "if 1 then 2 else 3",
  "if true then 1 else \"one\"",
  "len(42)",
  "let a = 1 in b",
  "frob(1)",
  "\"a\" == 1",
  "let x = in 3",
  "(1 + 2",
  "1 2"
]
programs.each do |src|
  e = parse(src)
  t = check(e, {})
  puts "#{src}\n  : #{t} = #{show_value(evaluate(e, {}))}"
rescue SyntaxErr => err
  puts "#{src}\n  syntax error: #{err.message} at '#{err.token}'"
rescue TypeErr => err
  puts "#{src}\n  type error: #{err.message}"
end

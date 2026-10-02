# A small calculator: tokenize, parse and evaluate lines like `x = 3 * (y + 2)`, reporting errors by column.
class ExprSyntaxError < StandardError
  attr_reader :column

  def initialize(message, column)
    super(message)
    @column = column
  end
end

class EvalError < StandardError
  attr_reader :name

  def initialize(message, name)
    super(message)
    @name = name
  end
end

class Token
  attr_reader :kind, :text, :column

  def initialize(kind, text, column)
    @kind = kind
    @text = text
    @column = column
  end
end

def tokenize(src)
  tokens = []
  i = 0
  n = src.length
  while i < n
    c = src[i]
    if c == " "
      i += 1
    elsif c.match?(/\d/)
      start = i
      i += 1 while i < n && src[i].match?(/\d/)
      tokens << Token.new(:num, src[start...i], start + 1)
    elsif c.match?(/[a-z]/)
      start = i
      i += 1 while i < n && src[i].match?(/[a-z0-9]/)
      tokens << Token.new(:ident, src[start...i], start + 1)
    elsif "+-*/()=%".include?(c)
      tokens << Token.new(:op, c, i + 1)
      i += 1
    else
      raise ExprSyntaxError.new("unexpected character '#{c}'", i + 1)
    end
  end
  tokens << Token.new(:eof, "", n + 1)
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
    @pos += 1
    t
  end

  def accept(text)
    t = peek
    return false unless t.kind == :op && t.text == text
    @pos += 1
    true
  end

  def expect(text)
    t = peek
    raise ExprSyntaxError.new("expected '#{text}' but found #{describe(t.text)}", t.column) unless accept(text)
  end

  def describe(text) = text.empty? ? "end of input" : "'#{text}'"

  # expr := term (('+'|'-') term)* ; term := factor (('*'|'/'|'%') factor)* ; factor := num | ident | '(' expr ')'
  def expr
    node = term
    loop do
      if accept("+") then node = [:add, node, term]
      elsif accept("-") then node = [:sub, node, term]
      else break
      end
    end
    node
  end

  def term
    node = factor
    loop do
      if accept("*") then node = [:mul, node, factor]
      elsif accept("/") then node = [:div, node, factor]
      elsif accept("%") then node = [:mod, node, factor]
      else break
      end
    end
    node
  end

  def factor
    t = advance
    case t.kind
    when :num then [:num, t.text.to_i, t.column]
    when :ident then [:var, t.text, t.column]
    else
      if t.text == "("
        inner = expr
        expect(")")
        return inner
      end
      raise ExprSyntaxError.new("unexpected #{describe(t.text)}", t.column)
    end
  end
end

def evaluate(node, env)
  kind, a, b = node
  case kind
  when :num then a
  when :var
    env.fetch(a) { raise EvalError.new("undefined variable #{a}", a) }
  else
    l = evaluate(a, env)
    r = evaluate(b, env)
    case kind
    when :add then l + r
    when :sub then l - r
    when :mul then l * r
    when :div, :mod
      raise EvalError.new("division by zero", "") if r.zero?
      kind == :div ? l / r : l % r
    end
  end
end

def run_line(src, env)
  tokens = tokenize(src)
  target = nil
  start = 0
  if tokens.size > 2 && tokens[0].kind == :ident && tokens[1].text == "="
    target = tokens[0].text
    start = 2
  end
  ps = Parser.new(tokens, start)
  tree = ps.expr
  last = ps.peek
  raise ExprSyntaxError.new("unexpected '#{last.text}' after expression", last.column) if last.kind != :eof
  value = evaluate(tree, env)
  env[target] = value if target
  [target, value]
end

program = [
  "x = 6 * 7",
  "y = (x - 2) / 4",
  "x + y * 2",
  "z = x / (y - 10)",
  "w = 3 +",
  "q = (1 + 2",
  "total = x + unknown",
  "a = 5 $ 3",
  "b = x % 5 + y % 3",
  "4 4",
  "c = ((b + 1) * (b - 1)) / 2"
]

env = {}
ok = 0
program.each do |line|
  target, value = run_line(line, env)
  ok += 1
  puts(target ? "#{target} = #{value}" : "=> #{value}")
rescue ExprSyntaxError => e
  puts line
  puts "#{" " * (e.column - 1)}^ syntax error: #{e.message}"
rescue EvalError => e
  puts "#{line}  !! #{e.message}"
end
puts "#{ok}/#{program.size} lines evaluated"
puts env.keys.sort.map { |k| "#{k}=#{env[k]}" }.join(" ")

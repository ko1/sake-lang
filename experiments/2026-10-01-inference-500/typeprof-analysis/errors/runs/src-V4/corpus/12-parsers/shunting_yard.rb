class ExprSyntaxError < StandardError
  attr_reader :token

  def initialize(message, token)
    super(message)
    @token = token
  end
end

class EvalError < StandardError
end

OPERATORS = {
  "+" => { prec: 1, right: false },
  "-" => { prec: 1, right: false },
  "*" => { prec: 2, right: false },
  "/" => { prec: 2, right: false },
  "^" => { prec: 3, right: true }
}

def number?(t) = t.match?(/\A\d+\z/)

def tokenize(src) = src.scan(%r{\d+|[-+*/^()]|\S+})

def to_rpn(tokens)
  out = []
  stack = []
  tokens.each do |t|
    if number?(t)
      out << t
    elsif OPERATORS.key?(t)
      prec = OPERATORS[t][:prec]
      right = OPERATORS[t][:right]
      while (top = stack.last) && top != "("
        top_prec = OPERATORS[top][:prec]
        break unless top_prec > prec || (top_prec == prec && !right)
        out << stack.pop
      end
      stack << t
    elsif t == "("
      stack << t
    elsif t == ")"
      loop do
        top = stack.pop
        raise ExprSyntaxError.new("unbalanced ')'", t) if !top    
        break if top == "("
        out << top
      end
    else
      raise ExprSyntaxError.new("unknown token", t)
    end
  end
  until stack.empty?
    top = stack.pop
    raise ExprSyntaxError.new("unbalanced '('", top) if top == "("
    out << top
  end
  out
end

def apply(op, a, b)
  case op
  when "+" then a + b
  when "-" then a - b
  when "*" then a * b
  when "/" then a / b
  else a**b
  end
end

def eval_rpn(rpn)
  stack = []
  rpn.each do |t|
    if number?(t)
      stack << Rational(Integer(t), 1)
    else
      b = stack.pop
      a = stack.pop
      raise EvalError, "missing operand for '#{t}'" if !a     || !b    
      stack << apply(t, a, b)
    end
  end
  raise EvalError, "expected one result, got #{stack.size}" unless stack.size == 1
  stack.first
end

def show(r) = r.denominator == 1 ? r.numerator.to_s : r.to_s

exprs = [
  "3 + 4 * 2 / ( 1 - 5 ) ^ 2 ^ 3",
  "1 / 3 + 1 / 6",
  "2 ^ 10 / 3",
  "(2 + 3) * (7 - 4) / 5",
  "10 - 4 - 3",
  "2 ^ 3 ^ 2",
  "(1 + 2",
  "1 + 2)",
  "7 / (3 - 3)",
  "1 +",
  "4 $ 2",
  "12 34"
]

ok = 0
exprs.each do |src|
  puts "expr:  #{src}"
  begin
    rpn = to_rpn(tokenize(src))
    puts "rpn:   #{rpn.join(" ")}"
    puts "value: #{show(eval_rpn(rpn))}"
    ok += 1
  rescue ExprSyntaxError => e
    puts "syntax error: #{e.message} (#{e.token})"
  rescue EvalError => e
    puts "eval error: #{e.message}"
  rescue ZeroDivisionError
    puts "eval error: division by zero"
  end
end
puts "#{ok}/#{exprs.size} evaluated"

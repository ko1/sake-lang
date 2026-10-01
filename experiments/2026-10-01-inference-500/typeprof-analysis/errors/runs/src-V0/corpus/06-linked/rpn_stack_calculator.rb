class Cell
  attr_reader :value, :below

  def initialize(value, below)
    @value = value
    @below = below
  end
end

class StackUnderflow < StandardError
  attr_reader :token

  def initialize(message, token)
    super(message)
    @token = token
  end
end

class BadToken < StandardError
  attr_reader :token, :position

  def initialize(message, token, position)
    super(message)
    @token = token
    @position = position
  end
end

class Stack
  attr_reader :top, :depth

  def initialize
    @top = nil
    @depth = 0
  end

  def push(v)
    @top = Cell.new(v, @top)
    @depth += 1
    self
  end

  def pop(token)
    cell = @top
    raise StackUnderflow.new("stack underflow at '#{token}'", token) if cell.nil?
    @top = cell.below
    @depth -= 1
    cell.value
  end

  def peek
    @top ? @top.value : nil
  end

  def to_s
    items = []
    cell = @top
    while cell
      items.unshift(cell.value)
      cell = cell.below
    end
    "[" + items.map { |x| format_num(x) }.join(" ") + "]"
  end
end

def format_num(x)
  x.is_a?(Float) ? x.round(4).to_s : x.to_s
end

def number?(tok) = tok.match?(/\A-?\d+(\.\d+)?\z/)

def parse_number(tok)
  tok.include?(".") ? tok.to_f : tok.to_i
end

def apply(op, a, b)
  case op
  when "+" then a + b
  when "-" then a - b
  when "*" then a * b
  when "/" then b == 0 ? raise(ZeroDivisionError, "divided by 0") : a / b
  when "%" then a % b
  when "^" then a**b
  when "max" then [a, b].max
  when "min" then [a, b].min
  end
end

BINARY = %w[+ - * / % ^ max min].freeze

def evaluate(expr, trace)
  stack = Stack.new
  expr.split(" ").each_with_index do |tok, i|
    if number?(tok)
      stack.push(parse_number(tok))
    elsif BINARY.include?(tok)
      b = stack.pop(tok)
      a = stack.pop(tok)
      stack.push(apply(tok, a, b))
    elsif tok == "dup"
      v = stack.pop(tok)
      stack.push(v).push(v)
    elsif tok == "swap"
      b = stack.pop(tok)
      a = stack.pop(tok)
      stack.push(b).push(a)
    elsif tok == "neg"
      stack.push(-stack.pop(tok))
    else
      raise BadToken.new("unknown token '#{tok}'", tok, i)
    end
    puts "    #{tok.ljust(5)} #{stack}" if trace
  end
  raise ArgumentError, "#{stack.depth} values left on stack" if stack.depth != 1
  stack.peek
end

exprs = [
  "3 4 + 2 *",
  "5 1 2 + 4 * + 3 -",
  "2 3 ^ 1 swap -",
  "1.5 2 * 0.25 +",
  "7 2 / 7 2 % max",
  "10 dup * neg 3 min",
  "4 +",
  "1 2 3 +",
  "8 0 /",
  "6 2 sqrt",
  "22 7.0 /"
]

traced = 0
exprs.each do |e|
  puts e
  begin
    result = evaluate(e, traced < 2)
    puts "  = #{format_num(result)}"
  rescue StackUnderflow => err
    puts "  error: #{err.message} (token #{err.token})"
  rescue BadToken => err
    puts "  error: #{err.message} at position #{err.position}"
  rescue ArgumentError, ZeroDivisionError => err
    puts "  error: #{err.message}"
  ensure
    traced += 1
  end
end

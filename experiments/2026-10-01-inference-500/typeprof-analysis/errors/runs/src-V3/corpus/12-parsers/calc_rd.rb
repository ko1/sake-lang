class ParseError < StandardError
  attr_reader :pos

  def initialize(message, pos)
    super(message)
    @pos = pos
  end
end

class UnknownName < StandardError
  attr_reader :name

  def initialize(message, name)
    super(message)
    @name = name
  end
end

class Calc
  attr_reader :pos

  def initialize(src, env)
    @src = src
    @pos = 0
    @env = env
  end

  def skip_ws
    @pos += 1 while @src[@pos] == " "
  end

  def peek
    skip_ws
    @src[@pos]
  end

  def expect(ch)
    got = peek
    raise ParseError.new("expected '#{ch}' but got #{got ? "'#{got}'" : "end"}", @pos) unless got == ch
    @pos += 1
  end

  def at_end? = peek.nil?

  def statement
    skip_ws
    if (m = @src[@pos..].match(/\A([a-z_][a-z0-9_]*)\s*=(?!=)/))
      name = m[1]
      @pos += m.to_s.size
      v = expr
      @env[name] = v
      return v
    end
    expr
  end

  def expr
    v = term
    loop do
      case peek
      when "+"
        @pos += 1
        v += term
      when "-"
        @pos += 1
        v -= term
      else
        break
      end
    end
    v
  end

  def term
    v = power
    loop do
      case peek
      when "*"
        @pos += 1
        v *= power
      when "/"
        @pos += 1
        v /= power
      when "%"
        @pos += 1
        v %= power
      else
        break
      end
    end
    v
  end

  def power
    base = unary
    if peek == "^"
      @pos += 1
      return base ** power
    end
    base
  end

  def unary
    if peek == "-"
      @pos += 1
      return -unary
    end
    primary
  end

  def primary
    ch = peek
    raise ParseError.new("unexpected end of input", @pos) if ch.nil?
    if ch == "("
      @pos += 1
      v = expr
      expect(")")
      return v
    end
    rest = @src[@pos..]
    if (m = rest.match(/\A\d+(\.\d+)?/))
      text = m.to_s
      @pos += text.size
      return m[1] ? Float(text) : Integer(text)
    end
    m = rest.match(/\A[a-z_][a-z0-9_]*/)
    raise ParseError.new("unexpected '#{ch}'", @pos) unless m
    name = m.to_s
    @pos += name.size
    if peek == "("
      @pos += 1
      args = [expr]
      while peek == ","
        @pos += 1
        args << expr
      end
      expect(")")
      return call(name, args)
    end
    v = @env[name]
    raise UnknownName.new("unknown variable", name) if v.nil?
    v
  end

  def call(name, args)
    case name
    when "max" then args.max
    when "min" then args.min
    when "abs" then args[0].abs
    when "sqrt" then Math.sqrt(args[0])
    else raise UnknownName.new("unknown function", name)
    end
  end
end

def evaluate(line, env)
  c = Calc.new(line, env)
  v = c.statement
  raise ParseError.new("trailing input", c.pos) unless c.at_end?
  v
end

def show(v) = v.is_a?(Float) ? v.round(6).to_s : v.to_s

env = { "pi" => 3.141592653589793 }
lines = [
  "1 + 2 * 3",
  "(1 + 2) * 3",
  "2 ^ 3 ^ 2",
  "-4 + 10 / 3",
  "17 % 5 * -2",
  "r = 2.5",
  "area = pi * r ^ 2",
  "area / 2",
  "max(3, 7 * 2, 9) - min(4, 1)",
  "sqrt(16) + abs(-3)",
  "x = (1 + 2",
  "4 / (2 - 2)",
  "y * 2",
  "foo(1)",
  "3 + * 4",
  "1 2",
  "count = count2 = 5"
]

lines.each_with_index do |line, i|
  v = evaluate(line, env)
  puts format("%2d  %-30s => %s", i + 1, line, show(v))
rescue ParseError => e
  puts format("%2d  %-30s !! parse error at %d: %s", i + 1, line, e.pos, e.message)
rescue UnknownName => e
  puts format("%2d  %-30s !! %s '%s'", i + 1, line, e.message, e.name)
rescue ZeroDivisionError
  puts format("%2d  %-30s !! division by zero", i + 1, line)
end

puts "variables:"
env.keys.sort.each { |k| puts "  #{k} = #{show(env[k])}" }

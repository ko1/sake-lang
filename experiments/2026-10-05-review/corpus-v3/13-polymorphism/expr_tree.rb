class UnboundVariable < StandardError
  attr_reader :name
  def initialize(message, name)
    super(message)
    @name = name
  end
end

module Expr
  def +(b) = Add.new(self, lift(b))
  def -(b) = Sub.new(self, lift(b))
  def *(b) = Mul.new(self, lift(b))
  def **(n) = Pow.new(self, n)

  def lift(x) = x.is_a?(Integer) ? Num.new(x) : x

  def evaluate(env) = raise("evaluate not implemented")
  def show = raise("show not implemented")
  def prec = 4
  def simplify = self
  def derive(v) = raise("derive not implemented")
  def size = 1

  def wrap(parent_prec) = prec < parent_prec ? "(#{show})" : show
  def to_s = show
end

class Num
  include Expr
  attr_reader :v
  def initialize(v)
    @v = v
  end
  def ==(o) = o.is_a?(Num) && o.v == @v
  def evaluate(env) = @v
  def show = @v.to_s
  def derive(v) = Num.new(0)
end

class Var
  include Expr
  attr_reader :name
  def initialize(name)
    @name = name
  end
  def ==(o) = o.is_a?(Var) && o.name == @name
  def evaluate(env)
    val = env[@name]
    raise UnboundVariable.new("unbound variable #{@name}", @name) if val.nil?
    val
  end
  def show = @name
  def derive(v) = Num.new(@name == v ? 1 : 0)
end

class Add
  include Expr
  attr_reader :l, :r
  def initialize(l, r)
    @l = l
    @r = r
  end
  def ==(o) = o.is_a?(Add) && o.l == @l && o.r == @r
  def evaluate(env) = @l.evaluate(env) + @r.evaluate(env)
  def show = "#{@l.wrap(1)} + #{@r.wrap(1)}"
  def prec = 1
  def size = 1 + @l.size + @r.size
  def derive(v) = @l.derive(v) + @r.derive(v)
  def simplify
    l = @l.simplify
    r = @r.simplify
    if l.is_a?(Num) && r.is_a?(Num)
      Num.new(l.v + r.v)
    elsif l == Num.new(0)
      r
    elsif r == Num.new(0)
      l
    elsif l == r
      Mul.new(Num.new(2), l)
    else
      Add.new(l, r)
    end
  end
end

class Sub
  include Expr
  attr_reader :l, :r
  def initialize(l, r)
    @l = l
    @r = r
  end
  def ==(o) = o.is_a?(Sub) && o.l == @l && o.r == @r
  def evaluate(env) = @l.evaluate(env) - @r.evaluate(env)
  def show = "#{@l.wrap(1)} - #{@r.wrap(2)}"
  def prec = 1
  def size = 1 + @l.size + @r.size
  def derive(v) = @l.derive(v) - @r.derive(v)
  def simplify
    l = @l.simplify
    r = @r.simplify
    if l.is_a?(Num) && r.is_a?(Num)
      Num.new(l.v - r.v)
    elsif r == Num.new(0)
      l
    elsif l == r
      Num.new(0)
    else
      Sub.new(l, r)
    end
  end
end

class Mul
  include Expr
  attr_reader :l, :r
  def initialize(l, r)
    @l = l
    @r = r
  end
  def ==(o) = o.is_a?(Mul) && o.l == @l && o.r == @r
  def evaluate(env) = @l.evaluate(env) * @r.evaluate(env)
  def show = "#{@l.wrap(2)} * #{@r.wrap(3)}"
  def prec = 2
  def size = 1 + @l.size + @r.size
  def derive(v) = @l.derive(v) * @r + @l * @r.derive(v)
  def simplify
    l = @l.simplify
    r = @r.simplify
    if l.is_a?(Num) && r.is_a?(Num)
      Num.new(l.v * r.v)
    elsif l == Num.new(0) || r == Num.new(0)
      Num.new(0)
    elsif l == Num.new(1)
      r
    elsif r == Num.new(1)
      l
    elsif r.is_a?(Num) && (l.is_a?(Var) || l.is_a?(Pow))
      Mul.new(r, l)
    elsif l == r
      Pow.new(l, 2)
    else
      Mul.new(l, r)
    end
  end
end

class Pow
  include Expr
  attr_reader :base, :n
  def initialize(base, n)
    @base = base
    @n = n
  end
  def ==(o) = o.is_a?(Pow) && o.base == @base && o.n == @n
  def evaluate(env) = @base.evaluate(env) ** @n
  def show = "#{@base.wrap(4)}^#{@n}"
  def prec = 3
  def size = 1 + @base.size
  def derive(v) = Num.new(@n) * Pow.new(@base, @n - 1) * @base.derive(v)
  def simplify
    b = @base.simplify
    if @n == 0
      Num.new(1)
    elsif @n == 1
      b
    elsif b.is_a?(Num)
      Num.new(b.v ** @n)
    else
      Pow.new(b, @n)
    end
  end
end

def x = Var.new("x")
def y = Var.new("y")

def report(label, e, env)
  s = e.simplify
  begin
    value = e.evaluate(env)
    puts "#{label}: #{e}  [size #{e.size}]"
    puts "   simplified: #{s}  [size #{s.size}]"
    puts "   value: #{value} (simplified: #{s.evaluate(env)})"
  rescue UnboundVariable => err
    puts "#{label}: #{e}"
    puts "   cannot evaluate: #{err.message}"
  end
end

env = { "x" => 3, "y" => -2 }
exprs = [
  ["poly", x ** 2 * 3 + x * 2 + 1],
  ["zeros", x * 0 + y * 1 + Num.new(0)],
  ["nested", (x + 1) * (x - 1) - (x ** 2 - 1)],
  ["mixed", (x + y) ** 3 - x * y * 2],
  ["consts", Num.new(2) * 3 + Num.new(4) ** 2],
  ["same", x * x + y + y],
  ["free", x + Var.new("z") * 2]
]

exprs.each { |label, e| report(label, e, env) }

puts "== derivatives d/dx =="
exprs.take(4).each do |label, e|
  d = e.derive("x").simplify
  puts "#{label}: #{d}  at x=3,y=-2 -> #{d.evaluate(env)}"
end

puts "== table of poly =="
poly = exprs[0][1]
(-2..2).each do |v|
  puts format("x=%2d  f=%3d", v, poly.evaluate({ "x" => v }))
end

biggest = exprs.max_by { |label, e| e.size }
puts "largest tree: #{biggest[0]}" if biggest

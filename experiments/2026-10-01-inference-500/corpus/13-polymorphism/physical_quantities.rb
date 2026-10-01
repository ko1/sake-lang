class DimensionMismatch < StandardError
  attr_reader :left, :right
  def initialize(message, left, right)
    super(message)
    @left = left
    @right = right
  end
end

# dims is an array [metre, kilogram, second] of exponents.
NAMED_UNITS = {
  [0, 0, 0] => "", [1, 0, 0] => "m", [0, 1, 0] => "kg", [0, 0, 1] => "s",
  [1, 0, -1] => "m/s", [1, 0, -2] => "m/s^2", [1, 1, -2] => "N", [2, 1, -2] => "J",
  [2, 1, -3] => "W", [-1, 1, -2] => "Pa", [3, 0, 0] => "m^3", [0, 0, -1] => "Hz"
}

PREFIXES = { "km" => [1000.0, "m"], "cm" => [0.01, "m"], "mm" => [0.001, "m"], "g" => [0.001, "kg"],
             "min" => [60.0, "s"], "h" => [3600.0, "s"], "t" => [1000.0, "kg"] }

class Qty
  include Comparable
  attr_reader :value, :dims

  def initialize(value, dims)
    @value = value
    @dims = dims
  end

  def self.unit_dims(name)
    case name
    in "m" then [1, 0, 0]
    in "kg" then [0, 1, 0]
    in "s" then [0, 0, 1]
    in "N" then [1, 1, -2]
    in "J" then [2, 1, -2]
    in "W" then [2, 1, -3]
    end
  end

  def self.parse(text)
    num, unit = text.split(" ")
    value = num.to_f
    dims = [0, 0, 0]
    sign = 1
    unit.scan(/[\/*]|[a-zA-Z]+(?:\^-?\d+)?/).each do |tok|
      if tok == "/"
        sign = -1
        next
      end
      next if tok == "*"
      name, pow = tok.split("^")
      exp = (pow ? pow.to_i : 1) * sign
      scale = PREFIXES[name]
      if scale
        factor, base = scale
        value *= factor ** exp
        name = base
      end
      d = unit_dims(name)
      dims = [dims[0] + d[0] * exp, dims[1] + d[1] * exp, dims[2] + d[2] * exp]
    end
    Qty.new(value, dims)
  end

  def self.unit_s(dims)
    named = NAMED_UNITS[dims]
    return named if named
    parts = []
    ["m", "kg", "s"].each_with_index do |sym, i|
      e = dims[i]
      next if e == 0
      parts << (e == 1 ? sym : "#{sym}^#{e}")
    end
    parts.join("*")
  end

  def check(b, op)
    unless @dims == b.dims
      raise DimensionMismatch.new("cannot #{op} #{Qty.unit_s(@dims)} and #{Qty.unit_s(b.dims)}", @dims, b.dims)
    end
  end

  def +(b)
    check(b, "add")
    Qty.new(@value + b.value, @dims)
  end

  def -(b)
    check(b, "subtract")
    Qty.new(@value - b.value, @dims)
  end

  def *(b)
    case b
    in Qty
      d = b.dims
      Qty.new(@value * b.value, [@dims[0] + d[0], @dims[1] + d[1], @dims[2] + d[2]])
    in Integer | Float then Qty.new(@value * b, @dims)
    end
  end

  def /(b)
    case b
    in Qty
      d = b.dims
      Qty.new(@value / b.value, [@dims[0] - d[0], @dims[1] - d[1], @dims[2] - d[2]])
    in Integer | Float then Qty.new(@value / b, @dims)
    end
  end

  def **(n) = Qty.new(@value ** n, [@dims[0] * n, @dims[1] * n, @dims[2] * n])

  def <=>(b)
    check(b, "compare")
    @value <=> b.value
  end

  def to_s
    u = Qty.unit_s(@dims)
    v = format("%.4g", @value)
    u == "" ? v : "#{v} #{u}"
  end
end

def kinetic_energy(m, v) = m * v ** 2 * 0.5

g = Qty.parse("9.81 m/s^2")
puts "g = #{g}"

inputs = ["72 kg", "36 km/h", "1.5 h", "250 g", "120 cm", "3 min", "2.5 t", "980 cm/s^2", "4 m^3"]
inputs.each { |s| puts format("%-12s -> %s", s, Qty.parse(s)) }

mass = Qty.parse("72 kg")
speed = Qty.parse("36 km/h")
trip = Qty.parse("1.5 h")
puts "distance = #{speed * trip}"
puts "weight = #{mass * g}"
puts "kinetic energy = #{kinetic_energy(mass, speed)}"
climb = Qty.parse("120 m")
work = mass * g * climb
puts "work to climb #{climb} = #{work}"
puts "power over 3 min = #{work / Qty.parse("3 min")}"
puts "pressure of #{mass * g} on 0.05 m^2 = #{mass * g / Qty.parse("0.05 m^2")}"
puts "frequency of 0.25 s period = #{Qty.parse("1 m") / Qty.parse("1 m") / Qty.parse("0.25 s")}"
puts "odd unit: #{Qty.parse("3 kg") * Qty.parse("2 s")}"
puts "dimensionless: #{Qty.parse("10 km") / Qty.parse("500 m")}"

legs = ["1.2 km", "800 m", "350 m", "2.05 km"].map { |s| Qty.parse(s) }
total = legs.reduce(Qty.parse("0 m")) { |acc, q| acc + q }
puts "legs: #{legs.join(" + ")} = #{total}"
puts "longest leg: #{legs.max}, shortest: #{legs.min}"
puts "sorted: #{legs.sort.join(" < ")}"

attempts = [["add", "5 m", "3 s"], ["compare", "2 J", "2 N"], ["add", "1 km", "10 m"]]
attempts.each do |op, a, b|
  qa = Qty.parse(a)
  qb = Qty.parse(b)
  begin
    result = op == "add" ? (qa + qb).to_s : (qa < qb).to_s
    puts "#{a} #{op} #{b} = #{result}"
  rescue DimensionMismatch => e
    puts "#{a} #{op} #{b}: #{e.message}"
  end
end

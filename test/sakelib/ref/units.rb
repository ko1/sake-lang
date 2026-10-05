# Reference implementation for test/sakelib/units.rb: quantities with units in plain Ruby, after the
# ruby-units gem, for length, mass, time and units made of them with *, / and ^n.
# Unit.new(scalar, units) (ruby-units takes one String: that is Unit.parse here).

class Unit
  include Comparable

  # name => [factor to the base unit, [length, mass, time] exponents]
  TABLE = {}.tap do |h|
    [["m", 1.0], ["km", 1000.0], ["cm", 0.01], ["mm", 0.001], ["in", 0.0254], ["ft", 0.3048],
     ["yd", 0.9144], ["mi", 1609.344]].each { |n, f| h[n] = [f, [1, 0, 0]] }
    [["kg", 1.0], ["g", 0.001], ["mg", 0.000001], ["t", 1000.0], ["lb", 0.45359237],
     ["oz", 0.028349523125]].each { |n, f| h[n] = [f, [0, 1, 0]] }
    [["s", 1.0], ["ms", 0.001], ["min", 60.0], ["h", 3600.0], ["day", 86400.0]].each { |n, f| h[n] = [f, [0, 0, 1]] }
    h["N"] = [1.0, [1, 1, -2]]
    h["J"] = [1.0, [2, 1, -2]]
    h["L"] = [0.001, [3, 0, 0]]
  end

  KINDS = { [0, 0, 0] => :unitless, [1, 0, 0] => :length, [0, 1, 0] => :mass, [0, 0, 1] => :time,
            [2, 0, 0] => :area, [3, 0, 0] => :volume, [1, 0, -1] => :speed, [1, 0, -2] => :acceleration,
            [1, 1, -2] => :force, [2, 1, -2] => :energy, [0, 0, -1] => :frequency }

  attr_reader :scalar, :units
  protected attr_reader :num, :den

  def initialize(scalar, units)
    scalar => Integer | Float
    units => String
    @scalar = scalar.to_f
    @num, @den = Unit.parse_units(units)
    @units = Unit.format_units(@num, @den)
  end

  def self.parse(s)
    m = /\A(-?\d+(?:\.\d+)?(?:e-?\d+)?)\s*(.*)\z/.match(s.strip)
    raise ArgumentError, "'#{s}' Unit not recognized" unless m
    new(Float(m[1]), m[2])
  end

  def self.parse_units(text)
    parts = text.strip.split("/", -1)
    raise ArgumentError, "'#{text}' Unit not recognized" if parts.size > 2
    cancel(names(parts.fetch(0, ""), text), names(parts.fetch(1, ""), text))
  end

  def self.names(part, text)
    p = part.strip
    return [] if p == "" || p == "1"
    p.split("*").flat_map do |tok|
      m = /\A([A-Za-z]+)(?:\^(\d+))?\z/.match(tok.strip)
      raise ArgumentError, "'#{text}' Unit not recognized" unless m
      raise ArgumentError, "'#{m[1]}' Unit not recognized" unless TABLE.key?(m[1])
      [m[1]] * (m[2] ? m[2].to_i : 1)
    end
  end

  def self.cancel(num, den)
    n = num.dup
    d = []
    den.each do |x|
      i = n.index(x)
      i ? n.delete_at(i) : d << x
    end
    [n, d]
  end

  def self.format_units(num, den)
    top = power_list(num)
    bottom = power_list(den)
    return top if bottom == ""
    "#{top == "" ? "1" : top}/#{bottom}"
  end

  def self.power_list(names) = names.tally.map { |n, k| k == 1 ? n : "#{n}^#{k}" }.join("*")

  def factor
    f = 1.0
    @num.each { |n| f *= TABLE.fetch(n)[0] }
    @den.each { |n| f /= TABLE.fetch(n)[0] }
    f
  end

  def dims
    d = [0, 0, 0]
    @num.each { |n| d = d.zip(TABLE.fetch(n)[1]).map { |a, b| a + b } }
    @den.each { |n| d = d.zip(TABLE.fetch(n)[1]).map { |a, b| a - b } }
    d
  end

  def kind = KINDS[dims] || :unknown
  def base_scalar = @scalar * factor
  def compatible?(other) = dims == other.dims

  def convert_to(target)
    t = Unit.new(1, target)
    raise ArgumentError, "Incompatible Units ('#{self}' not compatible with '#{target}')" unless compatible?(t)
    Unit.new(base_scalar / t.factor, t.units)
  end

  def to_base
    num = []
    den = []
    ["m", "kg", "s"].zip(dims).each { |n, k| (k > 0 ? num : den).concat([n] * k.abs) }
    Unit.new(base_scalar, Unit.format_units(num, den))
  end

  def +(other) = Unit.new(@scalar + other.convert_to(@units).scalar, @units)
  def -(other) = Unit.new(@scalar - other.convert_to(@units).scalar, @units)

  def *(other)
    return Unit.new(@scalar * other, @units) unless other.is_a?(Unit)
    n, d = Unit.cancel(@num + other.num, @den + other.den)
    Unit.new(@scalar * other.scalar, Unit.format_units(n, d))
  end

  def /(other)
    return Unit.new(@scalar / other, @units) unless other.is_a?(Unit)
    n, d = Unit.cancel(@num + other.den, @den + other.num)
    Unit.new(@scalar / other.scalar, Unit.format_units(n, d))
  end

  def <=>(other)
    raise ArgumentError, "Incompatible Units ('#{self}' not compatible with '#{other}')" unless compatible?(other)
    base_scalar <=> other.base_scalar
  end

  def round(digits = 0) = Unit.new(@scalar.round(digits), @units)
  def to_s = @units == "" ? format("%g", @scalar) : format("%g %s", @scalar, @units)
  def inspect = "#<Unit #{self}>"
end

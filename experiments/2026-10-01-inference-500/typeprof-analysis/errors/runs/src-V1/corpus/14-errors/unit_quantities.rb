# Parse quantities like "12.5 kg" or "3ft", convert between compatible units, and reject bad input.
class QuantityFormatError < StandardError
  attr_reader :input

  def initialize(message, input)
    super(message)
    @input = input
  end
end

class UnknownUnit < StandardError
  attr_reader :unit

  def initialize(message, unit)
    super(message)
    @unit = unit
  end
end

class IncompatibleUnits < StandardError
  attr_reader :from, :to

  def initialize(message, from, to)
    super(message)
    @from = from
    @to = to
  end
end

class Quantity
  attr_reader :value, :unit

  def initialize(value, unit)
    @value = value
    @unit = unit
  end
end

# unit => [dimension, factor to the base unit]
UNITS = {
  "mm" => [:length, 0.001], "cm" => [:length, 0.01], "m" => [:length, 1.0], "km" => [:length, 1000.0],
  "in" => [:length, 0.0254], "ft" => [:length, 0.3048],
  "g" => [:mass, 0.001], "kg" => [:mass, 1.0], "lb" => [:mass, 0.45359237],
  "s" => [:time, 1.0], "min" => [:time, 60.0], "h" => [:time, 3600.0]
}

ALIASES = { "meter" => "m", "meters" => "m", "feet" => "ft", "foot" => "ft", "hr" => "h", "sec" => "s" }

def parse_quantity(text)
  m = text.strip.match(/\A(-?\d+(?:\.\d+)?)\s*([a-zA-Z]+)\z/)
  raise QuantityFormatError.new("cannot parse '#{text}'", text) unless m
  unit = m[2].downcase
  unit = ALIASES.fetch(unit, unit)
  raise UnknownUnit.new("unknown unit '#{m[2]}'", m[2]) unless UNITS.key?(unit)
  Quantity.new(Float(m[1]), unit)
end

def convert(q, to)
  raise UnknownUnit.new("unknown unit '#{to}'", to) unless UNITS.key?(to)
  from_dim, from_factor = UNITS[q.unit]
  to_dim, to_factor = UNITS[to]
  raise IncompatibleUnits.new("cannot convert #{from_dim} to #{to_dim}", q.unit, to) if from_dim != to_dim
  raise ArgumentError, "negative #{from_dim}" if q.value < 0
  Quantity.new(q.value * from_factor / to_factor, to)
end

def fmt(q) = "#{q.value.round(3)} #{q.unit}"

requests = [
  ["12.5 kg", "lb"], ["3ft", "cm"], ["90 min", "h"], ["2 meters", "in"],
  ["5 parsecs", "m"], ["abc kg", "g"], ["10 kg", "m"], ["7 m", "yd"],
  ["-4 s", "min"], ["1500 g", "kg"], ["  42 Feet ", "m"], ["1.5.2 m", "cm"]
]

errors = {}
converted = []
requests.each do |text, target|
  q = parse_quantity(text)
  r = convert(q, target)
  converted << r
  puts format("%-12s -> %s", fmt(q), fmt(r))
rescue QuantityFormatError, UnknownUnit => e
  kind = e.is_a?(QuantityFormatError) ? "format" : "unit"
  errors[kind] = errors.fetch(kind, 0) + 1
  puts format("%-12s !! %s", text.strip, e.message)
rescue IncompatibleUnits => e
  errors["dimension"] = errors.fetch("dimension", 0) + 1
  puts format("%-12s !! %s (%s -> %s)", text.strip, e.message, e.from, e.to)
rescue ArgumentError
  errors["value"] = errors.fetch("value", 0) + 1
  puts format("%-12s !! rejected", text.strip)
end

lengths = converted.select { |q| UNITS[q.unit][0] == :length }
total_m = lengths.sum { |q| convert(q, "m").value }
puts "#{converted.size} converted; total length #{total_m.round(2)} m"
puts "errors: #{errors.keys.sort.map { |k| "#{k}=#{errors[k]}" }.join(" ")}"

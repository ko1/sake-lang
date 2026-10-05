# Validate nested JSON-like documents against a recursive schema, reporting errors with paths.
class Rule
  attr_reader :kind, :required, :fields, :item, :min, :max

  def initialize(kind, required, fields, item, min, max)
    @kind = kind
    @required = required
    @fields = fields
    @item = item
    @min = min
    @max = max
  end
end

def str(required) = Rule.new(:string, required, nil, nil, nil, nil)
def int(required, min, max) = Rule.new(:integer, required, nil, nil, min, max)
def obj(required, fields) = Rule.new(:object, required, fields, nil, nil, nil)
def list(required, item, min) = Rule.new(:array, required, nil, item, min, nil)

def order_schema
  obj(true, {
    "id" => int(true, 1, 999999),
    "customer" => obj(true, {
      "name" => str(true),
      "email" => str(false),
      "address" => obj(true, { "city" => str(true), "zip" => str(true) })
    }),
    "lines" => list(true, obj(true, { "sku" => str(true), "qty" => int(true, 1, 99) }), 1),
    "note" => str(false)
  })
end

def type_name(v)
  case v
  when Hash then "object"
  when Array then "array"
  when String then "string"
  when Integer then "integer"
  when nil then "null"
  else "other"
  end
end

def check(value, rule, path, errors)
  if value.nil?
    errors << [path, "is required"] if rule.required
    return
  end
  case rule.kind
  when :string
    return errors << [path, "expected string, got #{type_name(value)}"] unless value.is_a?(String)
    errors << [path, "must not be blank"] if value.strip.empty?
  when :integer
    return errors << [path, "expected integer, got #{type_name(value)}"] unless value.is_a?(Integer)
    errors << [path, "must be >= #{rule.min}"] if rule.min && value < rule.min
    errors << [path, "must be <= #{rule.max}"] if rule.max && value > rule.max
  when :object
    return errors << [path, "expected object, got #{type_name(value)}"] unless value.is_a?(Hash)
    rule.fields.each { |name, sub| check(value[name], sub, "#{path}.#{name}", errors) }
    (value.keys - rule.fields.keys).each { |k| errors << [path, "unexpected field #{k}"] }
  when :array
    return errors << [path, "expected array, got #{type_name(value)}"] unless value.is_a?(Array)
    errors << [path, "needs at least #{rule.min} item(s)"] if rule.min && value.size < rule.min
    value.each_with_index { |x, i| check(x, rule.item, "#{path}[#{i}]", errors) }
  end
end

docs = [
  { "id" => 17, "customer" => { "name" => "Ann", "address" => { "city" => "Kyoto", "zip" => "600" } },
    "lines" => [{ "sku" => "PEN", "qty" => 2 }] },
  { "id" => 0, "customer" => { "name" => " ", "email" => 42, "address" => { "city" => "Oslo" } },
    "lines" => [{ "sku" => "INK", "qty" => 120 }, { "qty" => 1 }, "PAD"] },
  { "id" => "18", "customer" => "Bob", "lines" => [], "gift" => true },
  { "customer" => { "name" => "Cy", "address" => { "city" => "Lima", "zip" => "15001", "floor" => 3 } },
    "lines" => { "sku" => "BAG" }, "note" => "rush" }
]

totals = Hash.new(0)
docs.each_with_index do |doc, i|
  errors = []
  check(doc, order_schema, "$", errors)
  if errors.empty?
    puts "doc #{i}: valid"
  else
    puts "doc #{i}: #{errors.size} error(s)"
    errors.each do |path, msg|
      puts "  #{path}: #{msg}"
      totals[msg.split(" ").first] += 1
    end
  end
end
puts totals.sort_by { |w, _| w }.map { |w, n| "#{w}=#{n}" }.join(", ")

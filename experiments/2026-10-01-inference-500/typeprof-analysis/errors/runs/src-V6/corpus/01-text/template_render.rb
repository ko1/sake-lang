class TemplateError < StandardError
  attr_reader :name

  def initialize(message, name)
    super(message)
    @name = name
  end
end

def apply_filter(value, filter)
  name, arg = filter.split(":")
  case name
  when "upper" then value.to_s.upcase
  when "lower" then value.to_s.downcase
  when "title"
    value.to_s.split(" ").map(&:capitalize).join(" ")
  when "join"
    value.is_a?(Array) ? value.map(&:to_s).join(!arg     ? ", " : arg) : value.to_s
  when "count"
    case value
    when Array, String then value.size
    else 1
    end
  when "money"
    raise TemplateError.new("money needs cents, got #{value}", filter) unless value.is_a?(Integer)
    format("$%d.%02d", value / 100, value % 100)
  when "pad" then value.to_s.ljust(arg.to_i)
  when "default" then !value     ? arg : value
  else raise TemplateError.new("unknown filter '#{name}'", filter)
  end
end

def lookup(context, path)
  path.split(".").reduce(context) do |value, key|
    return nil unless value.is_a?(Hash)
    value[key]
  end
end

def evaluate(context, expr)
  path, *filters = expr.split("|").map(&:strip)
  value = lookup(context, path)
  if !value     && filters.none? { |f| f.start_with?("default") }
    raise TemplateError.new("missing value for '#{path}'", path)
  end
  filters.reduce(value) { |v, f| apply_filter(v, f) }
end

def render(template, context)
  template.gsub(/\{\{([^}]*)\}\}/) { evaluate(context, $1.strip).to_s }
end

def templates
  [
    "Dear {{customer.name | title}},",
    "Your order no. {{order.id}} of {{order.items | count}} items ({{order.items | join:/}}) ships today.",
    "Total: {{order.total | money}}  Status: {{order.status | upper}}",
    "{{customer.city | default:unknown | upper}} / {{customer.name | pad:16}}|",
    "Coupon: {{order.coupon}}",
    "Shipping {{order.total | money | lower}} via {{carrier | frobnicate}}",
    "Weight: {{order.weight | money}}"
  ]
end

def context
  {
    "customer" => { "name" => "ada lovelace", "city" => nil },
    "order" => {
      "id" => 1042,
      "items" => ["notebook", "pencil", "ruler"],
      "total" => 12_345,
      "status" => "packed",
      "weight" => 2.5
    },
    "carrier" => "post"
  }
end

ctx = context
ok = 0
failed = 0
templates.each_with_index do |t, i|
  line = render(t, ctx)
  puts format("%2d ok   %s", i + 1, line)
  ok += 1
rescue TemplateError => e
  puts format("%2d FAIL %s [%s]", i + 1, e.message, e.name)
  failed += 1
end
puts "rendered #{ok}, failed #{failed}"

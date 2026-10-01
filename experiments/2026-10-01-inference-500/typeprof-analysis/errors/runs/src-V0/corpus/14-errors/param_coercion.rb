# Coerce raw string query parameters into typed values per a declared spec, collecting every coercion error.
class CoercionError < StandardError
  attr_reader :param, :raw

  def initialize(message, param, raw)
    super(message)
    @param = param
    @raw = raw
  end
end

# name => [type, required, default]
SEARCH_SPEC = [
  ["q", :string, true, ""],
  ["page", :int, false, "1"],
  ["per_page", :int, false, "20"],
  ["min_price", :decimal, false, ""],
  ["max_price", :decimal, false, ""],
  ["in_stock", :bool, false, "false"],
  ["sort", :enum, false, "relevance"],
  ["tags", :list, false, ""]
]

SORT_OPTIONS = %w[relevance price newest]

def coerce(name, kind, raw)
  case kind
  when :string then raw
  when :int
    raise CoercionError.new("#{name} must be an integer", name, raw) unless raw.match?(/\A\d+\z/)
    raw.to_i
  when :decimal
    raise CoercionError.new("#{name} must be a decimal", name, raw) unless raw.match?(/\A\d+(\.\d{1,2})?\z/)
    raw.to_r
  when :bool
    case raw.downcase
    when "1", "true", "yes", "on" then true
    when "0", "false", "no", "off" then false
    else raise CoercionError.new("#{name} must be a boolean", name, raw)
    end
  when :enum
    raise CoercionError.new("#{name} must be one of #{SORT_OPTIONS.join("/")}", name, raw) unless SORT_OPTIONS.include?(raw)
    raw.to_sym
  when :list
    raw.split(",").map(&:strip).reject(&:empty?)
  end
end

def parse_query(query)
  query.split("&").to_h do |pair|
    k, _sep, v = pair.partition("=")
    [k, v.gsub("+", " ")]
  end
end

def coerce_all(query)
  raw = parse_query(query)
  values = {}
  errors = []
  SEARCH_SPEC.each do |name, kind, required, default|
    given = raw[name]
    if given.nil? || given.empty?
      if required
        errors << "#{name} is required"
        next
      end
      next if default.empty?
      given = default
    end
    begin
      values[name] = coerce(name, kind, given)
    rescue CoercionError => e
      errors << "#{e.message} (got #{e.raw.inspect})"
    end
  end
  (raw.keys - SEARCH_SPEC.map(&:first)).each { |k| errors << "unknown parameter #{k}" }
  lo = values["min_price"]
  hi = values["max_price"]
  errors << "min_price is above max_price" if lo && hi && lo > hi
  [values, errors]
end

queries = [
  "q=red+shoes&page=2&in_stock=yes&tags=sale,+summer,",
  "page=x&per_page=50&sort=cheapest",
  "q=lamp&min_price=30&max_price=12.50&in_stock=maybe",
  "q=desk&min_price=9.999&color=oak&sort=price",
  "q=pen&page=&per_page=&max_price=4.5"
]

queries.each.with_index(1) do |query, n|
  values, errors = coerce_all(query)
  puts "query #{n}: #{query}"
  values.each { |k, v| puts "  #{k} = #{v.inspect}" }
  errors.each { |e| puts "  ! #{e}" }
end

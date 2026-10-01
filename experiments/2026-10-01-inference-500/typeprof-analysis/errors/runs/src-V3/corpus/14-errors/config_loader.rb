# Parse an INI-like config, type-check each setting against a schema, and report all problems.
class ParseError < StandardError
  attr_reader :line

  def initialize(message, line)
    super(message)
    @line = line
  end
end

class SchemaError < StandardError
  attr_reader :key

  def initialize(message, key)
    super(message)
    @key = key
  end
end

CONFIG_TEXT = "# server settings
[server]
host = example.org
port = 80800
workers = 4
debug = maybe

[database]
url = postgres://db/main
pool = 10
timeout = 2.5s
retries 3

[cache]
ttl = 300
[broken
enabled = yes
"

# kind, min, max
SCHEMA = {
  "server.host" => [:string, 0, 0],
  "server.port" => [:int, 1, 65535],
  "server.workers" => [:int, 1, 64],
  "server.debug" => [:bool, 0, 0],
  "database.url" => [:string, 0, 0],
  "database.pool" => [:int, 1, 100],
  "database.timeout" => [:float, 0, 60],
  "cache.ttl" => [:int, 0, 86400],
  "cache.enabled" => [:bool, 0, 0]
}

def parse_line(line, lineno, section)
  stripped = line.strip
  return [:blank, section, "", ""] if stripped.empty? || stripped.start_with?("#")
  if stripped.start_with?("[")
    m = stripped.match(/\A\[([a-z_]+)\]\z/)
    raise ParseError.new("bad section header #{stripped}", lineno) unless m
    return [:section, m[1], "", ""]
  end
  key, eq, value = stripped.partition("=")
  raise ParseError.new("expected key = value", lineno) if eq.empty?
  [:pair, section, key.strip, value.strip]
end

def convert(raw, rule, key)
  kind, lo, hi = rule
  case kind
  when :string
    raise SchemaError.new("must not be empty", key) if raw.empty?
    raw
  when :bool
    return true if %w[true yes on].include?(raw)
    return false if %w[false no off].include?(raw)
    raise SchemaError.new("not a boolean: #{raw}", key)
  when :int
    n = Integer(raw) rescue raise(SchemaError.new("not an integer: #{raw}", key))
    raise SchemaError.new("#{n} outside #{lo}..#{hi}", key) unless n.between?(lo, hi)
    n
  when :float
    f = Float(raw) rescue raise(SchemaError.new("not a number: #{raw}", key))
    raise SchemaError.new("#{f} outside #{lo}..#{hi}", key) unless f.between?(lo, hi)
    f
  end
end

def load(text)
  settings = {}
  problems = []
  section = "global"
  text.lines.each_with_index do |line, i|
    kind, section, key, value = parse_line(line, i + 1, section)
    next unless kind == :pair
    full = "#{section}.#{key}"
    rule = SCHEMA[full]
    raise SchemaError.new("unknown setting", full) unless rule
    settings[full] = convert(value, rule, full)
  rescue ParseError => e
    problems << "line #{e.line}: #{e.message}"
  rescue SchemaError => e
    problems << "line #{i + 1}: #{e.key}: #{e.message}"
  end
  SCHEMA.each_key do |k|
    problems << "missing: #{k}" unless settings.key?(k)
  end
  [settings, problems]
end

settings, problems = load(CONFIG_TEXT)
puts "loaded #{settings.size} of #{SCHEMA.size} settings"
settings.each { |k, v| puts "  #{k} = #{v.inspect}" }
puts "#{problems.size} problem(s):"
problems.each { |msg| puts "  #{msg}" }

class ConfigError < StandardError
  attr_reader :line_no

  def initialize(message, line_no)
    super(message)
    @line_no = line_no
  end
end

class Entry
  attr_reader :section, :key, :line_no
  attr_accessor :raw

  def initialize(section, key, raw, line_no)
    @section = section
    @key = key
    @raw = raw
    @line_no = line_no
  end

  def full_key = "#{section}.#{key}"
end

def parse_ini(text)
  entries = []
  section = "global"
  last = nil
  text.lines.each_with_index do |raw_line, i|
    line = raw_line.chomp
    no = i + 1
    if line.match?(/\A\s+\S/) && last
      last.raw += " " + line.strip
      next
    end
    line = line.strip
    next if line.empty? || line.start_with?("#", ";")
    if (m = line.match(/\A\[([\w.-]+)\]\z/)) && m
      section = m[1]
      last = nil
      next
    end
    kv = line.match(/\A([\w.-]+)\s*[=:]\s*(.*)\z/)
    raise ConfigError.new("cannot parse '#{line}'", no) unless kv
    value = kv[2].sub(/\s+[#;].*\z/, "")
    last = Entry.new(section, kv[1], value, no)
    entries << last
  end
  entries
end

def to_table(entries)
  entries.to_h { |e| [e.full_key, e.raw] }
end

def interpolate(table, value, depth)
  raise ConfigError.new("interpolation too deep in '#{value}'", 0) if depth > 5
  value.gsub(/\$\{([\w.-]+)\}/) do
    name = $1
    ref = table[name]
    raise ConfigError.new("undefined reference ${#{name}}", 0) if !ref    
    interpolate(table, ref, depth + 1)
  end
end

def coerce(s)
  case s
  when /\A".*"\z/ then s[1...-1]
  when /\A-?\d+\z/ then s.to_i
  when /\A-?\d+\.\d+\z/ then s.to_f
  else
    if ["true", "yes", "on"].include?(s.downcase)
      true
    elsif ["false", "no", "off"].include?(s.downcase)
      false
    elsif s.include?(",")
      s.split(",").map { |x| coerce(x.strip) }
    else
      s
    end
  end
end

def kind(v)
  case v
  when Integer then "int"
  when Float then "float"
  when true, false then "bool"
  when Array then "list[#{v.size}]"
  when String then "str"
  end
end

def load(text)
  entries = parse_ini(text)
  table = to_table(entries)
  entries.to_h do |e|
    [e.full_key, coerce(interpolate(table, e.raw, 0))]
  rescue ConfigError => err
    raise ConfigError.new(err.message, e.line_no)
  end
end

def config_text
  "# service configuration\n" \
  "name = billing\n" \
  "[server]\n" \
  "host = 0.0.0.0\n" \
  "port = 8080   ; default port\n" \
  "workers: 4\n" \
  "url = http://${server.host}:${server.port}/${global.name}\n" \
  "[db]\n" \
  "path = /var/${global.name}/data.db\n" \
  "timeout = 2.5\n" \
  "readonly = no\n" \
  "replicas = alpha, beta,\n" \
  "   gamma\n" \
  "motd = \"Welcome, ${global.name} users\"\n"
end

config = load(config_text)
width = config.keys.map(&:size).max
config.each do |k, v|
  puts "#{k.ljust(width)}  #{kind(v).ljust(8)} #{v.inspect}"
end
port = config["server.port"]
puts "next port: #{port + 1}" if port.is_a?(Integer)
["db.replicas", "db.missing"].each do |k|
  v = config.fetch(k, nil)
  puts !v     ? "#{k}: (not set)" : "#{k}: #{v.inspect}"
end

["[a]\nx = ${a.y}\ny = ${a.x}\n", "[a]\nnot a pair\n", "k = ${nope.k}\n"].each do |bad|
  load(bad)
  puts "loaded"
rescue ConfigError => e
  puts "config error (line #{e.line_no}): #{e.message}"
end

require "set"

class Section
  attr_reader :name, :entries, :line

  def initialize(name, entries, line)
    @name = name
    @entries = entries
    @line = line
  end
end

class Entry
  attr_accessor :key, :raw, :line

  def initialize(key, raw, line)
    @key = key
    @raw = raw
    @line = line
  end
end

class IniError < StandardError
  attr_reader :line

  def initialize(message, line)
    super(message)
    @line = line
  end
end

def parse_ini(text)
  sections = [Section.new("", {}, 0)]
  errors = []
  last = nil
  text.lines.each_with_index do |raw, idx|
    lineno = idx + 1
    line = raw.rstrip
    if line.match?(/\A\s+\S/) && last
      last.raw = last.raw + " " + line.strip
      next
    end
    line = line.strip
    last = nil
    next if line.empty? || line.start_with?("#") || line.start_with?(";")
    if (m = line.match(/\A\[([A-Za-z0-9_.]+)\]\z/)) && m
      name = m[1]
      errors << IniError.new("duplicate section [#{name}]", lineno) if sections.any? { |s| s.name == name }
      sections << Section.new(name, {}, lineno)
      next
    end
    if (m = line.match(/\A([A-Za-z_][\w.]*)\s*[=:]\s*(.*)\z/)) && m
      entry = Entry.new(m[1].downcase, m[2].sub(/\s+[#;].*\z/, ""), lineno)
      sections.last.entries[entry.key] = entry
      last = entry
    else
      errors << IniError.new("cannot parse: #{line}", lineno)
    end
  end
  [sections, errors]
end

def convert(raw, type)
  case type
  when :int
    raise ArgumentError, "not an integer: #{raw}" unless raw.match?(/\A-?\d+\z/)
    raw.to_i
  when :bool
    v = raw.downcase
    return true if %w[yes true on 1].include?(v)
    return false if %w[no false off 0].include?(v)
    raise ArgumentError, "not a boolean: #{raw}"
  when :list
    raw.split(",").map(&:strip).reject(&:empty?)
  else
    m = raw.match(/\A"(.*)"\z/)
    m ? m[1] : raw
  end
end

SCHEMA = [
  { section: "server", key: "host", type: :string, default: "localhost" },
  { section: "server", key: "port", type: :int, default: 8080 },
  { section: "server", key: "debug", type: :bool, default: false },
  { section: "server", key: "workers", type: :int, default: 4 },
  { section: "db", key: "url", type: :string, default: nil },
  { section: "db", key: "pool", type: :int, default: 5 },
  { section: "db", key: "replicas", type: :list, default: [] },
  { section: "log", key: "level", type: :string, default: "info" }
]

def load_config(text)
  sections, errors = parse_ini(text)
  config = {}
  SCHEMA.each do |rule|
    full = "#{rule[:section]}.#{rule[:key]}"
    sec = sections.find { |s| s.name == rule[:section] }
    entry = sec&.entries&.[](rule[:key])
    if !entry    
      if !rule[:default]    
        errors << IniError.new("missing required #{full}", 0)
      else
        config[full] = rule[:default]
      end
      next
    end
    begin
      config[full] = convert(entry.raw, rule[:type])
    rescue ArgumentError => e
      errors << IniError.new(e.message, entry.line)
    end
  end
  known = SCHEMA.map { |r| "#{r[:section]}.#{r[:key]}" }.to_set
  sections.each do |s|
    s.entries.each do |k, entry|
      full = "#{s.name}.#{k}"
      errors << IniError.new("unknown key #{full}", entry.line) unless known.include?(full)
    end
  end
  [config, errors.sort_by(&:line)]
end

def show(v)
  if v.is_a?(Array)
    "[" + v.map(&:inspect).join(", ") + "]"
  else
    v.inspect
  end
end

FILES = [
  ["good.ini", "# main server\n[server]\nhost = example.org\nport=9000\ndebug = yes ; temporary\n\n[db]\nurl: \"postgres://db/app\"\nreplicas = r1.local,\n    r2.local, r3.local\n[log]\nlevel = warn\n"],
  ["bad.ini", "[server]\nport = eighty\ndebug = maybe\ncolour = blue\n[db]\npool = 10\nthis line is junk\n[server]\nWorkers = 2\n"]
]

FILES.each do |name, text|
  puts "== #{name}"
  config, errors = load_config(text)
  config.keys.sort.each { |k| puts "  #{k.ljust(14)} = #{show(config[k])}" }
  errors.each do |e|
    puts "  #{e.line > 0 ? "line #{e.line}" : "config"}: #{e.message}"
  end
  puts "  #{errors.size} error(s)"
end

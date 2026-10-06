NAME = /\A[a-z0-9_]+\z/
REF = /\$\{([a-z0-9_]+(?:\.[a-z0-9_]+)?)\}/

class ResolveError < StandardError; end

class Config
  def initialize
    @values = {}   # "sec.key" => raw value
    @sections = {} # sec => [keys]
  end

  def section(name) = (@sections[name] ||= [])

  def set(sec, key, value)
    full = "#{sec}.#{key}"
    dup = @values.key?(full)
    @values[full] = value
    section(sec) << key unless dup
    dup
  end

  def keys(sec) = @sections[sec]&.sort

  def value(full) = @values[full]

  def key?(full) = @values.key?(full)

  def resolve(full, chain = [])
    if chain.include?(full)
      raise ResolveError, "cycle #{(chain + [full]).join(' -> ')}"
    end
    sec = full.split(".").first
    @values.fetch(full).gsub(REF) do
      ref = $1.include?(".") ? $1 : "#{sec}.#{$1}"
      raise ResolveError, "undefined #{ref}" unless @values.key?(ref)
      raise ResolveError, "no value #{ref}" if @values[ref].nil?
      resolve(ref, chain + [full])
    end
  end
end

def typed(v)
  if v.match?(/\A[+-]?\d+\z/)
    "int #{v.to_i}"
  elsif %w[true yes on].include?(v.downcase)
    "bool true"
  elsif %w[false no off].include?(v.downcase)
    "bool false"
  elsif v.include?(",")
    items = v.split(",").map(&:strip).reject(&:empty?)
    (["list[#{items.size}]"] + (items.empty? ? [] : [items.join(" | ")])).join(" ")
  else
    "str \"#{v}\""
  end
end

conf = Config.new
sec = "main"
in_queries = false
$stdin.each_line(chomp: true).with_index(1) do |raw, n|
  line = raw.strip
  unless in_queries
    if line == "%%"
      in_queries = true
    elsif line.empty? || line.start_with?("#", ";")
      # comment
    elsif (m = line.match(/\A\[(.*)\]\z/)) && m[1].match?(NAME)
      sec = m[1]
      conf.section(sec)
    elsif line.match?(NAME)
      puts "line #{n}: duplicate key #{sec}.#{line}" if conf.set(sec, line, nil)
    elsif line.include?("=") && (key = line.split("=", 2)[0].strip).match?(NAME)
      puts "line #{n}: duplicate key #{sec}.#{key}" if conf.set(sec, key, line.split("=", 2)[1].strip)
    else
      puts "line #{n}: syntax error"
    end
    next
  end
  next if line.empty?
  cmd, arg, extra = line.split
  if cmd == "GET" && arg && !extra
    full = arg.include?(".") ? arg : "main.#{arg}"
    if !conf.key?(full)
      puts "#{full}: not found"
    elsif conf.value(full).nil?
      puts "#{full}: no value"
    else
      begin
        puts "#{full} = #{typed(conf.resolve(full))}"
      rescue ResolveError => e
        puts "#{full}: error: #{e.message}"
      end
    end
  elsif cmd == "KEYS" && arg && !extra
    ks = conf.keys(arg)
    if ks.nil?
      puts "#{arg}: not found"
    else
      puts "#{arg}: #{ks.empty? ? '(none)' : ks.map { |k| conf.value("#{arg}.#{k}").nil? ? "#{k}?" : k }.join(', ')}"
    end
  else
    puts "line #{n}: bad query"
  end
end

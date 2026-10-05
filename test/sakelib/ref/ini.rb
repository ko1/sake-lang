# Reference implementation for sakelib/ini.sake: a small IniFile after the inifile gem.
class IniFile
  class Error < StandardError; end

  attr_accessor :filename

  def self.load(path, comment: ";#", parameter: "=", default: "global")
    return nil unless File.exist?(path)
    new(filename: path, content: File.read(path), comment: comment, parameter: parameter, default: default)
  end

  def initialize(filename: nil, content: nil, comment: ";#", parameter: "=", default: "global")
    @filename = filename
    @comment = comment
    @parameter = parameter
    @default = default
    @ini = {}
    parse(content) if content
  end

  ESCAPES = { "n" => "\n", "t" => "\t", "r" => "\r", "0" => "\0", "\\" => "\\", "\"" => "\"" }.freeze

  def [](section)
    @ini[section] ||= {}
  end

  def []=(section, hash)
    @ini[section] = hash
  end

  def sections = @ini.keys
  def has_section?(section) = @ini.key?(section)
  def delete_section(section) = @ini.delete(section)
  def to_h = @ini.transform_values(&:dup)

  def each
    @ini.each { |section, h| h.each { |k, v| yield section, k, v } }
    self
  end

  def each_section(&block)
    @ini.each_key(&block)
    self
  end

  def match(re) = @ini.select { |s, _| s.match?(re) }

  def merge(other)
    out = IniFile.new(filename: @filename, comment: @comment, parameter: @parameter, default: @default)
    [self, other].each { |src| src.each { |s, k, v| out[s][k] = v } }
    out
  end

  def to_s
    lines = []
    @ini.each do |section, h|
      lines << "[#{section}]"
      h.each { |k, v| lines << "#{k} #{@parameter} #{escape_value(v)}" }
      lines << ""
    end
    lines.join("\n")
  end

  def write(filename: @filename)
    raise Error, "no filename to write to" unless filename
    File.write(filename, to_s)
    self
  end

  private

  def parse(text)
    section = nil
    text.each_line do |raw|
      line = raw.strip
      next if line.empty? || @comment.include?(line[0])
      if (m = line.match(/\A\[\s*([^\]]*?)\s*\]\z/))
        section = m[1]
        @ini[section] ||= {}
        next
      end
      k = line.index(@parameter)
      raise Error, "Could not parse line '#{line}'" unless k && k > 0
      key = line[0, k].strip
      value = line[(k + @parameter.size)..].strip
      (@ini[section || @default] ||= {})[key] = typecast(value)
    end
  end

  def typecast(value)
    if value.start_with?("\"")
      m = value.match(/\A"((?:[^"\\]|\\.)*)"/) or raise Error, "Unterminated quoted value: #{value}"
      return m[1].gsub(/\\(.)/) { ESCAPES[$1] || $& }
    end
    v = value
    if (cm = v.match(/\s[#{Regexp.escape(@comment)}]/))
      v = cm.pre_match.rstrip
    end
    case v
    when "true" then true
    when "false" then false
    when /\A[-+]?\d+\z/ then v.to_i
    when /\A[-+]?\d+\.\d+(?:[eE][-+]?\d+)?\z/ then v.to_f
    else v
    end
  end

  def escape_value(v)
    v.to_s.gsub(/[\\\n\t\r\0]/, "\\" => "\\\\", "\n" => "\\n", "\t" => "\\t", "\r" => "\\r", "\0" => "\\0")
  end
end

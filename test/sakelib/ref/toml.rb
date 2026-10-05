# Reference implementation for sakelib/toml.sake: a TOML 1.0 subset after toml-rb (TomlRB.parse / dump).
require "set"
require "strscan"

module TOML
  class ParseError < StandardError
    attr_reader :line

    def initialize(msg, line)
      super(msg)
      @line = line
    end
  end

  ESCAPES = { "b" => "\b", "t" => "\t", "n" => "\n", "f" => "\f", "r" => "\r", "\"" => "\"", "\\" => "\\" }.freeze
  DUMP_ESCAPES = ESCAPES.to_h { |k, v| [v, "\\#{k}"] }.freeze

  class Parser
    def initialize(src, symbolize)
      @src = src
      @symbolize = symbolize
      @pos = 0
      @len = src.size
      @root = {}
      @current = @root
      @headers = Set.new
      @array_tables = Set.new
    end

    def parse
      loop do
        skip_all
        break if @pos >= @len
        if at?("[[")
          @pos += 2
          path = key_path
          expect("]]")
          array_table(path)
        elsif peek == "["
          @pos += 1
          path = key_path
          expect("]")
          table(path)
        else
          key_value(@current)
        end
        end_of_line
      end
      @root
    end

    private

    def peek = @src[@pos]
    def at?(s) = @src[@pos, s.size] == s

    def fail(msg)
      line = (@src[0, @pos] || "").count("\n") + 1
      raise ParseError.new("#{msg} at line #{line}", line)
    end

    def skip_ws
      @pos += 1 while @pos < @len && (peek == " " || peek == "\t")
    end

    def skip_comment
      @pos += 1 while @pos < @len && peek != "\n" if peek == "#"
    end

    def skip_all
      while @pos < @len
        skip_ws
        skip_comment
        break unless peek == "\n" || peek == "\r"
        @pos += 1
      end
    end

    def end_of_line
      skip_ws
      skip_comment
      @pos += 1 if at?("\r\n")
      return if @pos >= @len
      fail("expected end of line, got #{peek.inspect}") unless peek == "\n"
      @pos += 1
    end

    def expect(s)
      skip_ws
      fail("expected #{s.inspect}") unless at?(s)
      @pos += s.size
    end

    def key(k) = @symbolize ? k.to_sym : k

    def simple_key
      skip_ws
      return basic_string if peek == "\""
      return literal_string if peek == "'"
      m = @src.match(/\G[A-Za-z0-9_-]+/, @pos) or fail("expected a key")
      @pos += m[0].size
      m[0]
    end

    def key_path
      path = [simple_key]
      loop do
        skip_ws
        break unless peek == "."
        @pos += 1
        path << simple_key
      end
      path
    end

    def descend(h, path, header)
      path.each_with_index.reduce(h) do |t, (k, i)|
        kk = key(k)
        v = t[kk]
        if v.nil?
          t[kk] = {}
        elsif v.is_a?(Hash)
          v
        elsif header && v.is_a?(Array) && @array_tables.include?(path.first(i + 1))
          v.last
        else
          fail("key #{k} is already defined")
        end
      end
    end

    def table(path)
      fail("table #{path.join(".")} is defined twice") if @headers.include?(path)
      fail("table #{path.join(".")} is an array of tables") if @array_tables.include?(path)
      @headers << path
      @current = descend(@root, path, true)
    end

    def array_table(path)
      parent = descend(@root, path[0...-1], true)
      k = key(path.last)
      unless parent.key?(k)
        parent[k] = []
        @array_tables << path
      end
      a = parent[k]
      fail("key #{path.join(".")} is not an array of tables") unless a.is_a?(Array) && @array_tables.include?(path)
      a << (t = {})
      @current = t
      @headers.delete_if { |h| h.size > path.size && h.first(path.size) == path }
    end

    def key_value(h)
      path = key_path
      expect("=")
      skip_ws
      v = value
      t = descend(h, path[0...-1], false)
      k = key(path.last)
      fail("duplicate key #{path.last}") if t.key?(k)
      t[k] = v
    end

    def value
      c = peek
      fail("expected a value") if c.nil? || c == "\n"
      case c
      when "\"" then at?("\"\"\"") ? multiline_basic : basic_string
      when "'" then at?("'''") ? multiline_literal : literal_string
      when "[" then array
      when "{" then inline_table
      else
        if at?("true")
          @pos += 4
          true
        elsif at?("false")
          @pos += 5
          false
        else
          number
        end
      end
    end

    def array
      a = []
      @pos += 1
      loop do
        skip_all
        if peek == "]"
          @pos += 1
          break
        end
        a << value
        skip_all
        case peek
        when "," then @pos += 1
        when "]"
          @pos += 1
          break
        else fail("expected ',' or ']' in an array")
        end
      end
      a
    end

    def inline_table
      h = {}
      @pos += 1
      skip_ws
      if peek == "}"
        @pos += 1
        return h
      end
      loop do
        key_value(h)
        skip_ws
        case peek
        when "," then @pos += 1
        when "}"
          @pos += 1
          break
        else fail("expected ',' or '}' in an inline table")
        end
      end
      h
    end

    def number
      m = @src.match(/\G[0-9A-Za-z_+\-.:]+/, @pos) or fail("expected a value")
      s = m[0]
      fail("dates and times are not supported") if s.match?(/\A\d{4}-\d\d-\d\d|\A\d\d:\d\d/)
      v = TOML.number(s)
      fail("invalid value #{s}") if v.nil?
      @pos += s.size
      v
    end

    def unescape(body)
      body.gsub(/\\(?:u(\h{4})|U(\h{8})|[ \t]*\r?\n[ \t\r\n]*|(.))/m) do
        hex = $1 || $2
        e = $3
        if hex
          hex.hex.chr(Encoding::UTF_8)
        elsif e.nil?
          ""
        else
          ESCAPES[e] or fail("invalid escape \\#{e}")
        end
      end
    end

    def basic_string
      m = @src.match(/\G"((?:[^"\\\n]|\\.)*)"/, @pos) or fail("unterminated string")
      @pos += m[0].size
      unescape(m[1])
    end

    def literal_string
      m = @src.match(/\G'([^'\n]*)'/, @pos) or fail("unterminated string")
      @pos += m[0].size
      m[1]
    end

    def multiline_basic
      m = @src.match(/\G"""\r?\n?((?:[^\\]|\\.)*?"{0,2})"""/m, @pos) or fail("unterminated string")
      @pos += m[0].size
      unescape(m[1])
    end

    def multiline_literal
      m = @src.match(/\G'''\r?\n?(.*?'{0,2})'''/m, @pos) or fail("unterminated string")
      @pos += m[0].size
      m[1]
    end
  end

  module_function

  def parse(s, symbolize_keys: false) = Parser.new(s, symbolize_keys).parse
  def load_file(path, symbolize_keys: false) = parse(File.read(path), symbolize_keys: symbolize_keys)

  def number(s)
    return Float::INFINITY if s == "inf" || s == "+inf"
    return -Float::INFINITY if s == "-inf"
    return Float::NAN if %w[nan +nan -nan].include?(s)
    digits = /[0-9](?:_?[0-9])*/
    if s.match?(/\A[+-]?(?:0|[1-9](?:_?[0-9])*)\z/)
      s.delete("_").to_i
    elsif (m = s.match(/\A0([xob])([0-9A-Fa-f](?:_?[0-9A-Fa-f])*)\z/))
      body = m[2].delete("_")
      ok = case m[1]
           when "x" then true
           when "o" then body.match?(/\A[0-7]+\z/)
           else body.match?(/\A[01]+\z/)
           end
      ok ? "0#{m[1]}#{body}".oct : nil
    elsif s.match?(/\A[+-]?(?:0|[1-9](?:_?[0-9])*)(?:\.#{digits})?(?:[eE][+-]?#{digits})?\z/)
      Float(s.delete("_"))
    end
  end

  def dump_key(k)
    s = k.to_s
    s.match?(/\A[A-Za-z0-9_-]+\z/) ? s : dump_string(s)
  end

  def dump_string(s) = "\"#{s.gsub(/[\b\t\n\f\r"\\]/, DUMP_ESCAPES)}\""

  def dump_value(v)
    case v
    when String then dump_string(v)
    when Symbol then dump_string(v.to_s)
    when Integer then v.to_s
    when Float
      if v.nan? then "nan"
      elsif v.infinite? then v > 0 ? "inf" : "-inf"
      else v.to_s
      end
    when true then "true"
    when false then "false"
    when Array then "[#{v.map { |x| dump_value(x) }.join(", ")}]"
    when Hash
      return "{}" if v.empty?
      "{ #{v.map { |k, x| "#{dump_key(k)} = #{dump_value(x)}" }.join(", ")} }"
    else
      raise ArgumentError, "cannot dump #{v.inspect} to TOML"
    end
  end

  def table?(v) = v.is_a?(Hash)
  def table_array?(v) = v.is_a?(Array) && !v.empty? && v.all?(Hash)

  def dump(h)
    out = []
    dump_table(out, h, [])
    s = out.join("\n")
    s.empty? ? "" : s + "\n"
  end

  def dump_table(out, h, path)
    h.each { |k, v| out << "#{dump_key(k)} = #{dump_value(v)}" unless table?(v) || table_array?(v) }
    h.each do |k, v|
      sub = path + [dump_key(k)]
      name = sub.join(".")
      if v.is_a?(Hash)
        simple = v.any? { |_, x| !table?(x) && !table_array?(x) }
        if simple || v.empty?
          out << "" unless out.empty?
          out << "[#{name}]"
        end
        dump_table(out, v, sub)
      elsif table_array?(v)
        v.each do |t|
          out << "" unless out.empty?
          out << "[[#{name}]]"
          dump_table(out, t, sub)
        end
      end
    end
    out
  end
end

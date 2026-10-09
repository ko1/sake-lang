# Reference implementation of awesome_print's layout in plain Ruby, for test/sakelib/awesome_print.rb.
# It follows the gem's formatters (Inspector, Formatter, ArrayFormatter, HashFormatter, Indentator, Colors) for
# Arrays, Hashes and scalars; options are the gem's (indent, plain, index, multiline, sort_keys, ruby19_syntax).
# Not the gem: a Set prints as its Array (as the gem does); a Struct value is its inspect in the struct colour.

module AwesomePrint
  COLORS = {
    array: "1;37", hash: "0;37", integer: "1;34", float: "1;34", rational: "1;34", string: "0;33",
    symbol: "0;36", nilclass: "1;31", trueclass: "1;32", falseclass: "1;31", struct: "0;37"
  }

  class Inspector
    def initialize(indent:, plain:, index:, multiline:, sort_keys:, ruby19_syntax:)
      @indent = indent
      @plain = plain
      @index = index
      @multiline = multiline
      @sort_keys = sort_keys
      @ruby19_syntax = ruby19_syntax
      @indentation = indent.abs
    end

    def colorize(s, type)
      return s if @plain
      code = COLORS[type]
      code ? "\e[#{code}m#{s}\e[0m" : s
    end

    def awesome(v)
      case v
      when Array then awesome_array(v)
      when Set then awesome_array(v.to_a)
      when Hash then awesome_hash(v)
      when String then colorize(v.inspect, :string)
      when Symbol then colorize(v.inspect, :symbol)
      when Integer then colorize(v.to_s, :integer)
      when Float then colorize(v.inspect, :float)
      when Rational then colorize(v.to_s, :rational)
      when nil then colorize("nil", :nilclass)
      when true then colorize("true", :trueclass)
      when false then colorize("false", :falseclass)
      when Range, Regexp, Complex, Time, IO, MatchData then v.inspect
      else colorize(v.inspect, :struct)
      end
    end

    def indent_s = " " * @indentation
    def outdent = " " * (@indentation - @indent.abs)

    def indented
      @indentation += @indent.abs
      yield
    ensure
      @indentation -= @indent.abs
    end

    def awesome_array(a)
      return "[]" if a.empty?
      return "[ #{a.map { |x| awesome(x) }.join(", ")} ]" unless @multiline
      width = (a.size - 1).to_s.size
      lines = a.each_with_index.map do |item, i|
        prefix = @index ? indent_s + colorize("[#{i.to_s.rjust(width)}] ", :array) : indent_s
        prefix + indented { awesome(item) }
      end
      "[\n#{lines.join(",\n")}\n#{outdent}]"
    end

    def awesome_hash(h)
      return "{}" if h.empty?
      keys = h.keys
      keys = keys.sort_by(&:to_s) if @sort_keys
      data = keys.map { |k| [plain_single_line(k), h.fetch(k)] }
      width = data.map { |k, _| k.size }.max
      width += @indentation if @indent > 0
      lines = data.map do |k, v|
        indented do
          if @ruby19_syntax && k.start_with?(":")
            align(k[1..], width - 1) + colorize(": ", :hash) + awesome(v)
          else
            align(k, width) + colorize(" => ", :hash) + awesome(v)
          end
        end
      end
      return "{ #{lines.join(", ")} }" unless @multiline
      "{\n#{lines.join(",\n")}\n#{outdent}}"
    end

    def align(value, width)
      return value unless @multiline
      if @indent > 0
        value.rjust(width)
      elsif @indent == 0
        indent_s + value.ljust(width)
      else
        indent_s[0, @indentation + @indent] + value.ljust(width)
      end
    end

    def plain_single_line(k)
      plain, multiline = @plain, @multiline
      @plain = true
      @multiline = false
      awesome(k)
    ensure
      @plain, @multiline = plain, multiline
    end
  end

  module_function

  def ai(v, indent: 4, plain: false, index: true, multiline: true, sort_keys: false, ruby19_syntax: false)
    Inspector.new(indent: indent, plain: plain, index: index, multiline: multiline, sort_keys: sort_keys,
                  ruby19_syntax: ruby19_syntax).awesome(v)
  end

  def ap(v, **opts)
    puts ai(v, **opts)
    v
  end
end

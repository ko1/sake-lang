# frozen_string_literal: true

require_relative "errors"
require_relative "values"
require_relative "text"
require_relative "operators"

module Mini
  # The 25 built-in functions (SPEC section 10). The interpreter checks the
  # argument count before calling one; each then checks its arguments in
  # order and reports the first failure at the `(` of the call.
  module Builtins
    # Argument kinds: the phrase used in errors and the test.
    KINDS = {
      int: ["an int", ->(v) { v.is_a?(Integer) }],
      string: ["a string", ->(v) { v.is_a?(String) }],
      array: ["an array", ->(v) { v.is_a?(Array) }],
      map: ["a map", ->(v) { v.is_a?(Hash) }],
      function: ["a function", ->(v) { Values.function?(v) }],
      key: ["a string or int", ->(v) { Values.key?(v) }],
      int_or_string: ["an int or string", ->(v) { v.is_a?(Integer) || v.is_a?(String) }],
      sized: ["a string, array or map", ->(v) { v.is_a?(String) || v.is_a?(Array) || v.is_a?(Hash) }],
      sequence: ["an array or string", ->(v) { v.is_a?(Array) || v.is_a?(String) }],
      container: ["an array, map or string", ->(v) { v.is_a?(Array) || v.is_a?(Hash) || v.is_a?(String) }]
    }.freeze

    # One call of a built-in: its arguments, where it was called, and the
    # interpreter (for printing and for calling functions).
    class Invocation
      attr_reader :args, :position, :interpreter

      def initialize(builtin, args, position, interpreter)
        @builtin = builtin
        @args = args
        @position = position
        @interpreter = interpreter
      end

      # Checks the arguments present against `kinds` (nil: anything).
      def expect(*kinds)
        kinds.each_with_index do |kind, i|
          next if kind.nil? || i >= args.size

          phrase, test = KINDS.fetch(kind)
          next if test.call(args[i])

          fail(:type, "#{@builtin.name}: argument #{i + 1} must be #{phrase}, got #{Values.type_name(args[i])}")
        end
      end

      def fail(kind, message) = raise(EvalError.new(kind, message, position))

      # The same message with the built-in's name in front.
      def fail_own(kind, message) = fail(kind, "#{@builtin.name}: #{message}")
    end

    TABLE = {}

    def self.define(name, min, max = min, &impl)
      TABLE[name] = Builtin.new(name, min, max, impl).freeze
    end

    define("print", 0, nil) do |c|
      c.interpreter.write_line(c.args.map { |v| Text.str(v) }.join(" "))
      nil
    end

    define("len", 1) do |c|
      c.expect(:sized)
      c.args[0].size
    end

    define("push", 2) do |c|
      c.expect(:array)
      c.args[0].push(c.args[1])
      nil
    end

    define("pop", 1) do |c|
      c.expect(:array)
      c.fail_own(:value, "array is empty") if c.args[0].empty?
      c.args[0].pop
    end

    define("keys", 1) do |c|
      c.expect(:map)
      c.args[0].keys
    end

    define("values", 1) do |c|
      c.expect(:map)
      c.args[0].values
    end

    define("has", 2) do |c|
      c.expect(:map, :key)
      c.args[0].key?(c.args[1])
    end

    define("get", 2, 3) do |c|
      c.expect(:map, :key)
      c.args[0].fetch(c.args[1]) { c.args[2] }
    end

    define("del", 2) do |c|
      c.expect(:map, :key)
      map, key = c.args
      raise Operators.missing_key(key, c.position) unless map.key?(key)

      map.delete(key)
    end

    define("str", 1) { |c| Text.str(c.args[0]) }

    define("int", 1) do |c|
      c.expect(:int_or_string)
      value = c.args[0]
      next value if value.is_a?(Integer)

      c.fail_own(:value, "cannot convert #{Text.repr(value)} to int") unless value.match?(/\A-?[0-9]+\z/)
      value.to_i
    end

    define("type", 1) { |c| Values.type_name(c.args[0]) }

    define("range", 1, 3) do |c|
      c.expect(:int, :int, :int)
      first, last, step = c.args.size == 1 ? [0, c.args[0], 1] : [c.args[0], c.args[1], c.args[2] || 1]
      c.fail_own(:value, "step must not be zero") if step.zero?
      step.positive? ? first.step(last - 1, step).to_a : first.step(last + 1, step).to_a
    end

    define("join", 2) do |c|
      c.expect(:array, :string)
      c.args[0].map { |v| Text.str(v) }.join(c.args[1])
    end

    define("split", 2) do |c|
      c.expect(:string, :string)
      text, separator = c.args
      c.fail_own(:value, "separator must not be empty") if separator.empty?
      Builtins.split(text, separator)
    end

    define("slice", 2, 3) do |c|
      c.expect(:sequence, :int, :int)
      Operators.slice(c.args[0], c.args[1], c.args.size > 2 ? c.args[2] : Operators::OMITTED, c.position)
    end

    define("sort", 1) do |c|
      c.expect(:array)
      array = c.args[0]
      next array.dup if array.size <= 1

      first = array[0]
      array.drop(1).each do |element|
        comparable = (first.is_a?(Integer) && element.is_a?(Integer)) || (first.is_a?(String) && element.is_a?(String))
        next if comparable

        c.fail_own(:type, "cannot compare #{Values.type_name(first)} and #{Values.type_name(element)}")
      end
      array.sort
    end

    define("contains", 2) do |c|
      c.expect(:container)
      c.expect(nil, :string) if c.args[0].is_a?(String)
      Operators.member?(c.args[1], c.args[0], c.position)
    end

    %w[min max].each do |name|
      define(name, 1, nil) do |c|
        c.expect(*Array.new(c.args.size, :int))
        c.args.public_send(name)
      end
    end

    define("upper", 1) do |c|
      c.expect(:string)
      c.args[0].upcase
    end

    define("lower", 1) do |c|
      c.expect(:string)
      c.args[0].downcase
    end

    define("reverse", 1) do |c|
      c.expect(:sequence)
      c.args[0].reverse
    end

    define("map", 2) do |c|
      c.expect(:array, :function)
      array, function = c.args
      array.dup.map { |element| c.interpreter.call_function(function, [element], c.position) }
    end

    define("filter", 2) do |c|
      c.expect(:array, :function)
      array, function = c.args
      array.dup.select { |element| Values.truthy?(c.interpreter.call_function(function, [element], c.position)) }
    end

    TABLE.freeze

    # The pieces of `text` between occurrences of `separator`, keeping empty
    # ones. (Ruby's String#split drops trailing pieces and treats " " specially.)
    def self.split(text, separator)
      pieces = []
      start = 0
      while (found = text.index(separator, start))
        pieces << text[start...found]
        start = found + separator.size
      end
      pieces << text[start..]
    end
  end
end

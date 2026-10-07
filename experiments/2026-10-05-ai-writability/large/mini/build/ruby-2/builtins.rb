require_relative "errors"
require_relative "values"
require_relative "text"
require_relative "operators"

module Mini
  # The 25 built-in functions (section 10). The interpreter has already checked
  # the number of arguments; each implementation checks its arguments in order
  # and raises Faults, which are reported at the "(" of the call.
  module Builtins
    ALL = {}

    def self.define(name, min_args, max_args, &impl)
      ALL[name] = Builtin.new(name, min_args, max_args, impl).freeze
    end

    # Checks that argument `index` (0-based) has one of the `types`; `phrase`
    # is how the expected types are worded in the message.
    def self.expect(name, args, index, phrase, *types)
      value = args[index]
      return value if types.include?(Values.type_name(value))
      raise Fault.new("type",
                      "#{name}: argument #{index + 1} must be #{phrase}, got #{Values.type_name(value)}")
    end

    def self.int(name, args, index) = expect(name, args, index, "an int", "int")
    def self.string(name, args, index) = expect(name, args, index, "a string", "string")
    def self.array(name, args, index) = expect(name, args, index, "an array", "array")
    def self.map(name, args, index) = expect(name, args, index, "a map", "map")
    def self.key(name, args, index) = expect(name, args, index, "a string or int", "string", "int")

    def self.key_not_found(key) = Fault.new("key", "key #{Text.repr(key)} not found")

    # Positions i...j of a string or array, with the bounds of section 7.6.
    def self.slice(sequence, from, to)
      length = sequence.length
      from = clamp_bound(from || 0, length)
      to = clamp_bound(to || length, length)
      return sequence.is_a?(String) ? "" : [] if to <= from
      sequence[from...to]
    end

    def self.clamp_bound(bound, length)
      bound += length if bound.negative?
      bound.clamp(0, length)
    end

    define("print", 0, nil) do |interp, args, _call|
      interp.output(args.map { |arg| Text.str(arg) }.join(" ") + "\n")
      nil
    end

    define("len", 1, 1) do |_interp, args, _call|
      expect("len", args, 0, "a string, array or map", "string", "array", "map").length
    end

    define("push", 2, 2) do |_interp, args, _call|
      array("push", args, 0) << args[1]
      nil
    end

    define("pop", 1, 1) do |_interp, args, _call|
      array = array("pop", args, 0)
      raise Fault.new("value", "pop: array is empty") if array.empty?
      array.pop
    end

    define("keys", 1, 1) { |_interp, args, _call| map("keys", args, 0).keys }
    define("values", 1, 1) { |_interp, args, _call| map("values", args, 0).values }

    define("has", 2, 2) do |_interp, args, _call|
      map("has", args, 0).key?(key("has", args, 1))
    end

    define("get", 2, 3) do |_interp, args, _call|
      map = map("get", args, 0)
      key = key("get", args, 1)
      map.key?(key) ? map[key] : args[2]
    end

    define("del", 2, 2) do |_interp, args, _call|
      map = map("del", args, 0)
      key = key("del", args, 1)
      raise key_not_found(key) unless map.key?(key)
      map.delete(key)
    end

    define("str", 1, 1) { |_interp, args, _call| Text.str(args[0]) }

    define("int", 1, 1) do |_interp, args, _call|
      value = expect("int", args, 0, "an int or string", "int", "string")
      next value if value.is_a?(Integer)
      raise Fault.new("value", "int: cannot convert #{Text.repr(value)} to int") unless value.match?(/\A-?[0-9]+\z/)
      value.to_i
    end

    define("type", 1, 1) { |_interp, args, _call| Values.type_name(args[0]) }

    define("range", 1, 3) do |_interp, args, _call|
      args.each_index { |i| int("range", args, i) }
      start, stop, step = args.length == 1 ? [0, args[0], 1] : [args[0], args[1], args[2] || 1]
      raise Fault.new("value", "range: step must not be zero") if step.zero?
      result = []
      i = start
      while step.positive? ? i < stop : i > stop
        result << i
        i += step
      end
      result
    end

    define("join", 2, 2) do |_interp, args, _call|
      array = array("join", args, 0)
      separator = string("join", args, 1)
      array.map { |element| Text.str(element) }.join(separator)
    end

    define("split", 2, 2) do |_interp, args, _call|
      text = string("split", args, 0)
      separator = string("split", args, 1)
      raise Fault.new("value", "split: separator must not be empty") if separator.empty?
      text.empty? ? [""] : text.split(separator, -1)
    end

    define("slice", 2, 3) do |_interp, args, _call|
      sequence = expect("slice", args, 0, "an array or string", "array", "string")
      int("slice", args, 1)
      int("slice", args, 2) if args.length > 2
      slice(sequence, args[1], args[2])
    end

    # All ints or all strings; each element after the first is checked against
    # the first.
    define("sort", 1, 1) do |_interp, args, _call|
      array = array("sort", args, 0)
      next array.dup if array.length <= 1
      first_type = Values.type_name(array[0])
      array.drop(1).each do |element|
        type = Values.type_name(element)
        next if type == first_type && %w[int string].include?(type)
        raise Fault.new("type", "sort: cannot compare #{first_type} and #{type}")
      end
      array.sort
    end

    define("contains", 2, 2) do |_interp, args, _call|
      collection = expect("contains", args, 0, "an array, map or string", "array", "map", "string")
      string("contains", args, 1) if collection.is_a?(String)
      Operators.member?(args[1], collection)
    end

    define("min", 1, nil) do |_interp, args, _call|
      args.each_index { |i| int("min", args, i) }
      args.min
    end

    define("max", 1, nil) do |_interp, args, _call|
      args.each_index { |i| int("max", args, i) }
      args.max
    end

    define("upper", 1, 1) { |_interp, args, _call| string("upper", args, 0).upcase }
    define("lower", 1, 1) { |_interp, args, _call| string("lower", args, 0).downcase }

    define("reverse", 1, 1) do |_interp, args, _call|
      expect("reverse", args, 0, "an array or string", "array", "string").reverse
    end

    define("map", 2, 2) do |interp, args, call|
      array = array("map", args, 0)
      function = expect("map", args, 1, "a function", "function")
      array.dup.map { |element| interp.call_function(function, [element], call) }
    end

    define("filter", 2, 2) do |interp, args, call|
      array = array("filter", args, 0)
      function = expect("filter", args, 1, "a function", "function")
      array.dup.select { |element| Values.truthy?(interp.call_function(function, [element], call)) }
    end

    ALL.freeze
  end
end

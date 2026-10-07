require_relative "errors"

module Mini
  # Mini values are represented by Ruby values:
  #   int -> Integer, string -> String (never mutated), bool -> true/false,
  #   nil -> nil, array -> Array, map -> Hash (insertion ordered),
  #   function -> UserFunction or Builtin.

  # A closure: a function node and the scope it was created in.
  UserFunction = Struct.new(:node, :env) do
    def name = node.name
    def display_name = node.name || "function"
    def min_args = node.params.count { |param| param.default.nil? }
    def max_args = node.params.length
  end

  # A built-in function; `max_args` is nil when there is no maximum. The
  # implementation receives (interpreter, args, call node).
  Builtin = Struct.new(:name, :min_args, :max_args, :impl) do
    def display_name = name
  end

  # Values nested deeper than this are not compared or written (sections 4, 8.1).
  MAX_NESTING = 100

  module Values
    module_function

    def type_name(value)
      case value
      when Integer then "int"
      when String then "string"
      when true, false then "bool"
      when nil then "nil"
      when Array then "array"
      when Hash then "map"
      when UserFunction, Builtin then "function"
      else raise ArgumentError, "not a Mini value: #{value.inspect}"
      end
    end

    def truthy?(value) = !(value.nil? || value == false)

    def valid_key?(value) = value.is_a?(Integer) || value.is_a?(String)

    def check_key(value)
      return if valid_key?(value)
      raise Fault.new("type", "map key must be a string or int, got #{type_name(value)}")
    end

    # Equality of section 4; raises a "value" Fault past MAX_NESTING levels.
    def equal_values?(a, b, level = 0)
      raise Fault.new("value", "values nested too deeply to compare") if level > MAX_NESTING

      case a
      when Array
        b.is_a?(Array) && a.length == b.length &&
          a.each_index.all? { |i| equal_values?(a[i], b[i], level + 1) }
      when Hash
        b.is_a?(Hash) && a.length == b.length &&
          a.all? { |key, value| b.key?(key) && equal_values?(value, b[key], level + 1) }
      when UserFunction, Builtin
        a.equal?(b)
      else
        type_name(a) == type_name(b) && a == b
      end
    end

    # "f expects 2 arguments, got 3" and its variants (section 6.6).
    def arity_message(function, given)
      min = function.min_args
      max = function.max_args
      expected =
        if max.nil? then "at least #{plural(min, "argument")}"
        elsif min == max then plural(min, "argument")
        else "#{min} to #{max} arguments"
        end
      "#{function.display_name} expects #{expected}, got #{given}"
    end

    def plural(n, noun) = n == 1 ? "1 #{noun}" : "#{n} #{noun}s"
  end
end

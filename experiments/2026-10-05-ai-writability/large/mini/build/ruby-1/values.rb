# frozen_string_literal: true

require_relative "errors"

module Mini
  # Mini values are plain Ruby objects: Integer (int), String (string),
  # true/false (bool), nil, Array (array), Hash (map, insertion ordered, keys
  # Integer or String). Functions are the two classes below.

  # A closure: a function literal together with the scope it was created in.
  class UserFunction
    attr_reader :name, :params, :body, :closure

    def initialize(literal, closure)
      @name = literal.name
      @params = literal.params
      @body = literal.body
      @closure = closure
    end

    def min_arity = params.count { |p| p.default.nil? }

    def max_arity = params.size

    # The name used in arity errors.
    def display_name = name || "function"
  end

  # A built-in function. `max` is nil when it takes any number of arguments;
  # `impl` is called with a Builtins::Invocation.
  Builtin = Struct.new(:name, :min, :max, :impl)

  # Type names, truthiness and equality (SPEC section 4).
  module Values
    MAX_COMPARE_LEVEL = 100

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

    def function?(value) = value.is_a?(UserFunction) || value.is_a?(Builtin)

    def key?(value) = value.is_a?(Integer) || value.is_a?(String)

    # Structural equality. Errors (nesting too deep) are reported at `position`.
    def equal?(a, b, position, level = 0)
      if level > MAX_COMPARE_LEVEL
        raise EvalError.new(:value, "values nested too deeply to compare", position)
      end

      case a
      when Integer, String
        b.instance_of?(a.class) && a == b
      when Array
        b.is_a?(Array) && a.size == b.size &&
          a.each_index.all? { |i| equal?(a[i], b[i], position, level + 1) }
      when Hash
        b.is_a?(Hash) && a.size == b.size &&
          a.all? { |key, value| b.key?(key) && equal?(value, b[key], position, level + 1) }
      else
        a.equal?(b) # true, false, nil, and functions by identity
      end
    end
  end
end

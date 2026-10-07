# frozen_string_literal: true

require_relative "values"

module Mini
  # `str` and `repr` (SPEC section 8.1).
  module Text
    MAX_LEVEL = 100
    ESCAPES = { "\\" => "\\\\", "\"" => "\\\"", "{" => "\\{", "\n" => "\\n", "\t" => "\\t" }.freeze

    module_function

    def str(value) = value.is_a?(String) ? value : repr(value)

    def repr(value, level = 0)
      return "..." if level > MAX_LEVEL

      case value
      when String then "\"#{value.gsub(/[\\"{\n\t]/, ESCAPES)}\""
      when Integer then value.to_s
      when true then "true"
      when false then "false"
      when nil then "nil"
      when Array then "[#{value.map { |e| repr(e, level + 1) }.join(", ")}]"
      when Hash then "{#{value.map { |k, v| "#{repr(k, level + 1)}: #{repr(v, level + 1)}" }.join(", ")}}"
      when UserFunction then value.name ? "<fn #{value.name}>" : "<fn>"
      when Builtin then "<builtin #{value.name}>"
      else raise ArgumentError, "not a Mini value: #{value.inspect}"
      end
    end
  end
end

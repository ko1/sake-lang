require_relative "values"

module Mini
  # `str` and `repr` (section 8.1).
  module Text
    module_function

    REPR_ESCAPES = { "\\" => "\\\\", "\"" => "\\\"", "{" => "\\{", "\n" => "\\n", "\t" => "\\t" }.freeze

    def str(value) = value.is_a?(String) ? value : repr(value)

    def repr(value)
      out = +""
      write_repr(out, value, 0)
      out
    end

    def write_repr(out, value, level)
      return out << "..." if level > MAX_NESTING

      case value
      when Integer then out << value.to_s
      when String then out << "\"" << value.gsub(/[\\"{\n\t]/, REPR_ESCAPES) << "\""
      when true, false, nil then out << value.inspect
      when Array
        out << "["
        value.each_with_index do |element, i|
          out << ", " if i > 0
          write_repr(out, element, level + 1)
        end
        out << "]"
      when Hash
        out << "{"
        value.each_with_index do |(key, element), i|
          out << ", " if i > 0
          write_repr(out, key, level + 1)
          out << ": "
          write_repr(out, element, level + 1)
        end
        out << "}"
      when UserFunction then out << (value.name ? "<fn #{value.name}>" : "<fn>")
      when Builtin then out << "<builtin #{value.name}>"
      end
    end
  end
end

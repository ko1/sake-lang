# frozen_string_literal: true

module Sake
  # Operators dispatch on the type of their left operand (the subject), like a mixin function of the
  # module that offers them: `a + b` is Arithmetic.+(a, b), which runs (type of a).+(a, b).
  module Operators
    MODULE_OF = {
      "+" => "Arithmetic", "-" => "Arithmetic", "*" => "Arithmetic", "/" => "Arithmetic", "%" => "Arithmetic", "**" => "Arithmetic",
      "<=>" => "Comparable", "<" => "Comparable", "<=" => "Comparable", ">" => "Comparable", ">=" => "Comparable",
      "&" => "Bitwise", "|" => "Bitwise", "^" => "Bitwise", "<<" => "Bitwise", ">>" => "Bitwise",
      "==" => "Kernel", "!=" => "Kernel", "=~" => "Kernel", "!~" => "Kernel",
      "[]" => "Indexable", "[]=" => "Indexable",
      "-@" => "Arithmetic", "+@" => "Arithmetic", "~" => "Bitwise" # unary: `-x`, `+x`, `~x`
    }.freeze
    UNARY = %w[-@ +@ ~].freeze
    MODULES = %w[Arithmetic Comparable Bitwise Indexable].freeze

    # The modules each built-in type includes (every type also includes Kernel).
    BUILTIN = {
      "Integer" => %w[Arithmetic Comparable Bitwise], "Float" => %w[Arithmetic Comparable],
      "Rational" => %w[Arithmetic Comparable], "Complex" => %w[Arithmetic],
      "String" => %w[Arithmetic Comparable Indexable], "Time" => %w[Arithmetic Comparable],
      "Set" => %w[Arithmetic Bitwise], "Array" => %w[Arithmetic Comparable Indexable], "Hash" => %w[Indexable],
      "Tuple" => %w[Comparable Indexable], "MatchData" => %w[Indexable], "Symbol" => %w[Comparable]
    }.freeze

    # `a OP b` / `x[k]` / `Arithmetic.+(a, b)`: dispatch op of mod on the first argument's type.
    Call = Struct.new(:module, :op)

    module_function

    def includes?(includes, type, mod)
      mod == "Kernel" || BUILTIN.fetch(type, []).include?(mod) || includes.fetch(type, []).include?(mod)
    end
  end
end

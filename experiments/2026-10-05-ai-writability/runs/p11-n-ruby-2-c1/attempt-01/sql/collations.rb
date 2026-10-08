# frozen_string_literal: true

require_relative 'errors'

module SQL
  # What an expression or result column says about collation (SPEC 7.3): `collation` is :binary,
  # :nocase, :rtrim, or nil for none; `explicit` is true for a COLLATE. Compiled has the same two readers.
  Collated = Struct.new(:collation, :explicit)

  # Collating sequences (SPEC 7): how two TEXT values compare. A collation is a Symbol; nil means BINARY.
  module Collations
    NAMES = { 'binary' => :binary, 'nocase' => :nocase, 'rtrim' => :rtrim }.freeze
    NONE = Collated.new(nil, false).freeze

    module_function

    # The collation called `name` (any case), else the 7.2 error.
    def resolve(name) = NAMES.fetch(name.downcase) { raise SqlError, "no such collation sequence: #{name}" }

    # Collation of `a op b` (7.4): explicit left, explicit right, implicit left, implicit right, BINARY.
    # `left` and `right` respond to `collation` / `explicit`.
    def choose(left, right)
      return left.collation if left.explicit
      return right.collation if right.explicit

      left.collation || right.collation || :binary
    end

    # A text that compares byte by byte (binary string) in the way `collation` compares texts;
    # equal under the collation exactly when the results are equal.
    def fold(text, collation)
      case collation
      when :nocase then text.b.tr('A-Z', 'a-z')
      when :rtrim then text.b.sub(/ +\z/, '')
      else text
      end
    end
  end
end

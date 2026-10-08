module MiniSql
  # Collating sequences (SPEC 7): how two TEXT values compare. A collation is :binary, :nocase or :rtrim.
  module Collation
    # The collation called `name` (any case); SqlError for an unknown name.
    def self.lookup(name)
      case name.upcase(:ascii)
      when "BINARY" then :binary
      when "NOCASE" then :nocase
      when "RTRIM" then :rtrim
      else raise SqlError, "no such collation sequence: #{name}"
      end
    end

    # The text as the collation compares it: equal after folding means equal under the collation.
    def self.fold(text, collation)
      case collation
      when :nocase then text.tr("A-Z", "a-z")
      when :rtrim then text.sub(/ +\z/, "")
      else text
      end
    end

    def self.compare(left, right, collation)
      return (left <=> right) || 0 if collation == :binary
      (fold(left, collation) <=> fold(right, collation)) || 0
    end

    # The collation of `left op right` (SPEC 7.4): explicit left, explicit right, implicit left, implicit right,
    # else BINARY.
    def self.choose(left_explicit, left_implicit, right_explicit, right_implicit)
      left_explicit || right_explicit || left_implicit || right_implicit || :binary
    end

    # `choose` for two bound expressions.
    def self.of_exprs(left, right)
      choose(left.explicit_collation, left.implicit_collation, right.explicit_collation, right.implicit_collation)
    end
  end
end

# frozen_string_literal: true

require_relative "ast"
require_relative "errors"
require_relative "identifier"

module Sql
  # Collating sequences (7): how two TEXT values compare. A collation is a symbol: :binary (the
  # default), :nocase or :rtrim. Which one an operation uses is decided from the bound expressions.
  module Collation
    NAMES = { "binary" => :binary, "nocase" => :nocase, "rtrim" => :rtrim }.freeze
    TRAILING_SPACES = / +\z/

    module_function

    # The collation named `name` as written (nil: none written, so :binary), or the 7.7 error.
    def lookup(name)
      return :binary if name.nil?
      NAMES.fetch(Sql.fold(name)) { raise SqlError, "no such collation sequence: #{name}" }
    end

    # Order of two TEXT values under the collation: -1, 0 or 1.
    def compare_text(a, b, collation)
      key(a, collation) <=> key(b, collation)
    end

    # A string such that two TEXT values are equal under the collation iff their keys are eql?, and
    # whose byte order is the collation's order.
    def key(text, collation)
      case collation
      when :nocase then text.b.tr("A-Z", "a-z")
      when :rtrim then text.b.sub(TRAILING_SPACES, "")
      else text.b
      end
    end

    # The key to hash a TEXT value by (GROUP BY, DISTINCT, UNIQUE); BINARY leaves the value as it is.
    def hash_key(text, collation)
      collation == :binary ? text : key(text, collation)
    end

    # What a bound expression says about its collation (7.3): nil (none), or [name, explicit?].
    def info(node)
      case node
      when Collate then [node.name, true]
      when ColumnRef then [node.collation, false]
      when Cast then info(node.expr)
      when Unary then node.op == :plus ? info(node.operand) : nil
      when OuterExpr then info(node.expr)
      end
    end

    # The collation an expression sorts / groups / dedups by (explicit or implicit), else :binary.
    def of(node)
      (info(node) || [:binary]).first
    end

    # The collation of the result column an expression is (nil when it has none), for compound selects.
    def named(node)
      info(node)&.first
    end

    # The collation of a comparison `a op b` from the infos of its operands (7.4).
    def choose(info_a, info_b)
      return info_a[0] if info_a&.last
      return info_b[0] if info_b&.last
      (info_a || info_b || [:binary]).first
    end

    # The collation of `left_node op right_node` (bound expressions).
    def for_comparison(left_node, right_node)
      choose(info(left_node), info(right_node))
    end
  end
end

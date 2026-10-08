# frozen_string_literal: true

require_relative "ast"
require_relative "errors"
require_relative "identifier"

module Sql
  # Collating sequences (7): :binary, :nocase and :rtrim. How a text is turned into the key that
  # collation compares by is Values.text_key; here are the names and which collation an expression has.
  module Collation
    NAMES = { "binary" => :binary, "nocase" => :nocase, "rtrim" => :rtrim }.freeze

    module_function

    # The collation named `name` (as written), or the 7.7 error.
    def resolve(name)
      NAMES[Sql.fold(name)] or raise SqlError, "no such collation sequence: #{name}"
    end

    # [:explicit | :implicit, collation] for a bound expression, or nil when it has none (7.3).
    def info(node)
      case node
      when Collate then [:explicit, node.collation]
      when ColumnRef then [:implicit, node.collation]
      when Cast, OuterExpr then info(node.expr)
      when Unary then node.op == :plus ? info(node.operand) : nil
      end
    end

    # The collation the values of one expression are compared under among themselves (7.4).
    def of(node)
      info(node)&.last || :binary
    end

    # The collation of `a op b` given the infos of the two operands (7.4).
    def choose(a_info, b_info)
      return a_info[1] if a_info&.first == :explicit
      return b_info[1] if b_info&.first == :explicit
      (a_info || b_info)&.last || :binary
    end

    # `expr COLLATE name` at the top of an unbound sort / group term -> [expr, collation or nil]. It is
    # taken off so that a term naming a result column by number or alias can be given the collation.
    def peel(expr)
      expr.is_a?(Collate) ? [expr.expr, resolve(expr.collation)] : [expr, nil]
    end
  end
end

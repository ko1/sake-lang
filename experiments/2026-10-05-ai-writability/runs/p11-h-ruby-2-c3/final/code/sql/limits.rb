# frozen_string_literal: true

require_relative 'compiler'
require_relative 'errors'
require_relative 'scope'
require_relative 'values'

module SQL
  # LIMIT / OFFSET (1.7) and the ordinals of ORDER BY / GROUP BY, shared by SELECT and compound selects.
  module Limits
    module_function

    # [limit or nil, offset] of the clauses (expressions or nil); a negative limit means none.
    def resolve(limit_expr, offset_expr, namespace)
      limit = limit_expr && integer_clause(limit_expr, namespace)
      limit = nil if limit&.negative?
      offset = offset_expr ? [integer_clause(offset_expr, namespace), 0].max : 0
      [limit, offset]
    end

    def window(rows, limit, offset)
      rows = rows.drop(offset)
      limit ? rows.take(limit) : rows
    end

    def integer_clause(expr, namespace)
      v = Compiler.new(Scope.empty(namespace)).compile(expr).fn.call(nil)
      v = Values.parse_numeric_literal(v) || v if v.is_a?(String)
      v = v.to_i if v.is_a?(Float) && v == v.floor
      raise SqlError, 'datatype mismatch' unless v.is_a?(Integer)

      v
    end

    # k for an integer literal or `-` integer literal, else nil.
    def ordinal(expr)
      case expr
      when Literal then expr.value if expr.value.is_a?(Integer)
      when Unary
        v = expr.operand
        -v.value if expr.op == :neg && v.is_a?(Literal) && v.value.is_a?(Integer)
      end
    end

    # Index of the k-th of `width` result columns for the term at `position` of `clause` ('ORDER' or 'GROUP').
    def ordinal_index(k, position, clause, width)
      unless k.between?(1, width)
        raise SqlError, "#{ordinal_word(position + 1)} #{clause} BY term out of range - should be between 1 and #{width}"
      end
      k - 1
    end

    def ordinal_word(n)
      suffix = if (11..13).cover?(n % 100) then 'th'
               else { 1 => 'st', 2 => 'nd', 3 => 'rd' }.fetch(n % 10, 'th')
               end
      "#{n}#{suffix}"
    end
  end
end

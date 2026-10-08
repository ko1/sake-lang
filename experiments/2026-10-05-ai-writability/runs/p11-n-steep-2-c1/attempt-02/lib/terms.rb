module MiniSql
  # Helpers for ORDER BY and GROUP BY terms (SPEC 1.7, 3.3).
  module Terms
    # k for an integer literal k or `-k`, else nil.
    def self.ordinal(expr)
      if expr.is_a?(Literal) && expr.value.is_a?(Integer)
        expr.value
      elsif expr.is_a?(Unary) && expr.op == "-"
        inner = ordinal(expr.operand)
        inner ? -inner : nil
      end
    end

    # `e COLLATE n` as [e, "n"]; any other expression as [expr, nil].
    def self.split_collate(expr)
      expr.is_a?(CollateExpr) ? [expr.operand, expr.name] : [expr, nil]
    end

    # 1 as "1st", 2 as "2nd", 11 as "11th", ...
    def self.nth(number)
      suffix =
        if (11..13).cover?(number % 100) then "th"
        else { 1 => "st", 2 => "nd", 3 => "rd" }.fetch(number % 10, "th")
        end
      "#{number}#{suffix}"
    end

    # Raises the out-of-range error unless the term at `position` (0-based) of `clause` ("ORDER BY") names a
    # result column of 1..count.
    def self.check_ordinal(ordinal, position, clause, count)
      return if ordinal.between?(1, count)
      raise SqlError, "#{nth(position + 1)} #{clause} term out of range - should be between 1 and #{count}"
    end
  end
end

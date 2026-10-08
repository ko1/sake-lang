module MiniSql
  # A subquery inside an expression (SPEC 4.3). It runs for every row it is evaluated on, with the frame of the
  # enclosing query set to that row, so that correlated references read it.
  class BoundSubquery < Expr
    attr_reader :plan

    def initialize(plan, frame)
      @plan = plan
      @frame = frame
    end

    def evaluate(row)
      raise NotImplementedError, "evaluate"
    end

    private

    def rows_for(row)
      @frame.row = row
      @plan.rows
    end
  end

  # `( select )`: the first column of the first row, NULL without rows.
  class BoundScalar < BoundSubquery
    def affinity
      @plan.columns.fetch(0).affinity
    end

    def evaluate(row)
      first = rows_for(row).first
      first ? first.fetch(0, nil) : nil
    end
  end

  # `EXISTS ( select )`.
  class BoundExists < BoundSubquery
    def evaluate(row)
      rows_for(row).empty? ? 0 : 1
    end
  end

  # `operand [NOT] IN ( select )`: as the list form, but each value has its column's affinity and collation
  # (each test is `operand = column`, SPEC 7.4).
  class BoundIn < BoundSubquery
    def initialize(operand, negated, plan, frame)
      super(plan, frame)
      @operand = operand
      @negated = negated
    end

    def children
      [@operand]
    end

    def evaluate(row)
      value = Evaluator.evaluate(@operand, row)
      found = 0 # @type var found: Integer?
      column = @plan.columns.fetch(0)
      collation = Collation.choose(@operand.explicit_collation, @operand.implicit_collation,
                                   column.explicit_collation, column.implicit_collation)
      rows_for(row).each do |candidate|
        test = Operators.compare("=", value, @operand.affinity, candidate.fetch(0, nil), column.affinity, collation)
        found = Operators.logic_or(found, test)
        break if found == 1
      end
      @negated ? Operators.logic_not(found) : found
    end
  end
end

module MiniSql
  # Plans a compound select (SPEC 5.1): every arm, the column counts, and the ORDER BY of the whole.
  class CompoundPlanner
    def initialize(database, select, outer, ctes)
      @database = database
      @select = select
      @outer = outer
      @ctes = ctes
      @environment = Environment.new(database, RowFrame.new, outer, ctes)
    end

    def plan
      first = plan_of(@select.first)
      steps = @select.arms.map do |arm|
        arm_plan = plan_of(arm.select)
        unless arm_plan.columns.length == first.columns.length
          raise SqlError, "SELECTs to the left and right of #{arm.op} do not have the same number of result columns"
        end
        CompoundStep.new(arm.op, arm_plan)
      end
      keys = sort_keys(first, steps)
      limit, offset = Limits.resolve(@select.limit, @select.offset, @environment)
      CompoundPlan.new(first, steps, first.columns, keys, limit, offset)
    end

    private

    def plan_of(select)
      Planner.new(@database, select, @outer, @ctes).plan
    end

    # An ORDER BY term is a column number or the name of a result column.
    def sort_keys(first, steps)
      @select.order_by.each_with_index.map do |term, position|
        ordinal = Terms.ordinal(term.expr)
        if ordinal
          Terms.check_ordinal(ordinal, position, "ORDER BY", first.columns.length)
          next SortKey.new(ordinal - 1, nil, term.descending, term.nulls)
        end
        index = named_column(term.expr, [first] + steps.map(&:plan))
        unless index
          raise SqlError, "#{Terms.nth(position + 1)} ORDER BY term does not match any column in the result set"
        end
        SortKey.new(index, nil, term.descending, term.nulls)
      end
    end

    # The position of the result column a name stands for, looking in each plan in turn.
    def named_column(expr, plans)
      return nil unless expr.is_a?(ColumnRef)
      wanted = expr.name.downcase(:ascii)
      plans.each do |plan|
        index = plan.columns.index { |column| column.name&.downcase(:ascii) == wanted }
        return index if index
      end
      nil
    end
  end
end

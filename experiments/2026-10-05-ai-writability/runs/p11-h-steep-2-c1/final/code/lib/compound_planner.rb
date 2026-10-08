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
      collations = Collation.of_compound([first.columns] + steps.map { |step| step.plan.columns })
      columns = first.columns.each_with_index.map do |column, i|
        SourceColumn.new(column.name, column.affinity, collations.fetch(i), false)
      end
      keys = sort_keys(first, steps, collations)
      limit, offset = Limits.resolve(@select.limit, @select.offset, @environment)
      CompoundPlan.new(first, steps, columns, keys, limit, offset)
    end

    private

    def plan_of(select)
      Planner.new(@database, select, @outer, @ctes).plan
    end

    # An ORDER BY term is a column number or the name of a result column, with the column's collation (those of
    # the compound, SPEC 7.4) unless it has its own COLLATE.
    def sort_keys(first, steps, collations)
      @select.order_by.each_with_index.map do |term, position|
        inner, collate = Terms.split_collate(term.expr)
        named = collate ? Collation.resolve(collate) : nil
        ordinal = Terms.ordinal(inner)
        if ordinal
          Terms.check_ordinal(ordinal, position, "ORDER BY", first.columns.length)
          next SortKey.new(ordinal - 1, nil, term.descending, term.nulls, named || collations.fetch(ordinal - 1))
        end
        index = named_column(inner, [first] + steps.map(&:plan))
        unless index
          raise SqlError, "#{Terms.nth(position + 1)} ORDER BY term does not match any column in the result set"
        end
        SortKey.new(index, nil, term.descending, term.nulls, named || collations.fetch(index))
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

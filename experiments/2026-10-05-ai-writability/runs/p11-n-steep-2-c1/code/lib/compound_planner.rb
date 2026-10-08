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
      columns = merged_columns(first, steps)
      keys = sort_keys(first, steps, columns)
      limit, offset = Limits.resolve(@select.limit, @select.offset, @environment)
      CompoundPlan.new(first, steps, columns, keys, limit, offset)
    end

    private

    def plan_of(select)
      Planner.new(@database, select, @outer, @ctes).plan
    end

    # The columns of the compound: the first arm's names and affinities, and for each position the collation of the
    # first arm whose column has one (SPEC 7.4), else BINARY.
    def merged_columns(first, steps)
      plans = [first] + steps.map(&:plan)
      first.columns.each_with_index.map do |column, position|
        SourceColumn.new(column.name, column.affinity, first_collation(plans, position), false)
      end
    end

    def first_collation(plans, position)
      plans.each do |plan|
        found = plan.columns.fetch(position).collation
        return found if found
      end
      :binary
    end

    # An ORDER BY term is a column number or the name of a result column, optionally followed by COLLATE; it sorts
    # under that collation, else under the column's.
    def sort_keys(first, steps, columns)
      @select.order_by.each_with_index.map do |term, position|
        inner, written = Terms.split_collate(term.expr)
        explicit = written && Collation.lookup(written)
        index = result_index(inner, position, first, steps)
        SortKey.new(index, nil, term.descending, term.nulls, explicit || columns.fetch(index).source_collation)
      end
    end

    # The position of the result column an ORDER BY term stands for.
    def result_index(expr, position, first, steps)
      ordinal = Terms.ordinal(expr)
      if ordinal
        Terms.check_ordinal(ordinal, position, "ORDER BY", first.columns.length)
        return ordinal - 1
      end
      index = named_column(expr, [first] + steps.map(&:plan))
      unless index
        raise SqlError, "#{Terms.nth(position + 1)} ORDER BY term does not match any column in the result set"
      end
      index
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

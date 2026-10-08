module MiniSql
  # Plans the tables of a WITH clause (SPEC 5.2) into a CteScope that the select after it is planned with.
  class CtePlanner
    # outer and ctes are those of the select the WITH clause belongs to.
    def initialize(database, outer, ctes)
      @database = database
      @outer = outer
      @ctes = ctes
    end

    # The scope with every table of the clause on top of the enclosing one; each table sees those before it.
    def scope_for(with)
      scope = @ctes
      seen = {} # @type var seen: Hash[String, bool]
      with.tables.each do |table|
        key = table.name.downcase(:ascii)
        raise SqlError, "duplicate WITH table name: #{table.name}" if seen[key]
        seen[key] = true
        scope = CteScope.new(scope, plan_table(with, table, scope))
      end
      scope
    end

    private

    def plan_table(with, table, scope)
      body = table.select
      return plan_recursive(table, body, scope) if with.recursive && body.is_a?(CompoundSelect) && recursive?(table, body)
      plan = Planner.new(@database, body, @outer, scope).plan
      PlannedCte.new(table.name, SourceColumn.rename(plan.columns, table.columns), plan)
    end

    # `initial UNION [ALL] step` whose step reads the cte itself.
    def recursive?(table, body)
      arm = body.arms.first
      return false unless body.arms.length == 1 && arm
      return false unless arm.op == "UNION" || arm.op == "UNION ALL"
      from = arm.select.from
      !from.nil? && from.mentions_table?(table.name)
    end

    def plan_recursive(table, body, scope)
      arm = body.arms.fetch(0)
      initial = Planner.new(@database, body.first, @outer, scope).plan
      columns = SourceColumn.rename(initial.columns, table.columns)
      working = WorkingSet.new
      inner = CteScope.new(scope, RecursiveCte.new(table.name, columns, working))
      step = Planner.new(@database, arm.select, @outer, inner).plan
      unless step.columns.length == initial.columns.length
        raise SqlError, "SELECTs to the left and right of #{arm.op} do not have the same number of result columns"
      end
      environment = Environment.new(@database, RowFrame.new, @outer, scope)
      limit, offset = Limits.resolve(body.limit, body.offset, environment)
      collations = Collation.of_compound([initial.columns, step.columns])
      plan = RecursivePlan.new(initial, step, working, arm.op == "UNION ALL", columns, collations, limit, offset)
      PlannedCte.new(table.name, columns, plan)
    end
  end
end

module MiniSql
  # Runs a simple SELECT (see QueryPlan#rows).
  class Query
    def initialize(plan)
      @plan = plan
    end

    # Pipeline: joined rows, WHERE, groups and HAVING, window calls, result values, DISTINCT, ORDER BY, OFFSET / LIMIT.
    def rows
      plan = @plan
      where = plan.where
      kept = plan.from.rows.select { |row| where.nil? || Value.truth(Evaluator.evaluate(where, row)) == true }
      candidates = candidates_of(plan, plan.windows.extended(group_rows(plan, kept)))
      candidates = distinct(candidates) if plan.distinct
      keys = plan.keys
      candidates = candidates.sort { |a, b| SortKey.compare_candidates(keys, a, b) } unless keys.empty?
      Limits.slice(candidates, plan.limit, plan.offset).map(&:values)
    end

    private

    # The rows the result columns, HAVING and ORDER BY are evaluated on: the rows themselves, or in an
    # aggregate query the group row of each group that HAVING keeps.
    def group_rows(plan, rows)
      scope = plan.aggregates
      return rows unless scope
      group_rows = Grouping.partition(rows, plan.group_by).map { |group| scope.group_row(group) }
      having = plan.having
      return group_rows unless having
      group_rows.select { |row| Value.truth(Evaluator.evaluate(having, row)) == true }
    end

    def candidates_of(plan, rows)
      rows.each_with_index.map do |row, serial|
        values = plan.results.map { |expr| Evaluator.evaluate(expr, row) }
        Candidate.new(values, plan.keys.map { |key| key.value(values, row) }, serial)
      end
    end

    # One candidate of each set of equal result rows (1.9, NULLs equal), the first one.
    def distinct(candidates)
      seen = {} # @type var seen: Hash[Array[sql_value], bool]
      candidates.select do |candidate|
        key = RowSet.key(candidate.values)
        seen[key] ? false : (seen[key] = true)
      end
    end
  end
end

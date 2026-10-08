module MiniSql
  # Runs a SELECT and returns its printed lines.
  class Query
    def initialize(plan)
      @plan = plan
    end

    def lines
      rows.map { |values| values.map { |value| Value.render(value) }.join("|") }
    end

    # Pipeline: joined rows, WHERE, groups and HAVING, result values, DISTINCT, ORDER BY, OFFSET / LIMIT.
    def rows
      plan = @plan
      where = plan.where
      kept = plan.from.rows.select { |row| where.nil? || Value.truth(Evaluator.evaluate(where, row)) == true }
      candidates = candidates_of(plan, group_rows(plan, kept))
      candidates = distinct(candidates) if plan.distinct
      keys = plan.keys
      candidates = candidates.sort { |a, b| SortKey.compare_candidates(keys, a, b) } unless keys.empty?
      window(candidates, plan.limit, plan.offset).map(&:values)
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
        key = candidate.values.map { |value| Value.group_key(value) }
        seen[key] ? false : (seen[key] = true)
      end
    end

    def window(candidates, limit, offset)
      rest = candidates.drop(offset)
      limit ? rest.first(limit) : rest
    end
  end
end

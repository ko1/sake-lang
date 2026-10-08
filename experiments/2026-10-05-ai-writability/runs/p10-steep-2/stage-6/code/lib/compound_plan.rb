module MiniSql
  # One `op plan` of a compound select; op is "UNION", "UNION ALL", "INTERSECT" or "EXCEPT".
  class CompoundStep
    attr_reader :op, :plan

    def initialize(op, plan)
      @op = op
      @plan = plan
    end
  end

  # A compound select (SPEC 5.1): the first plan combined with each step from left to right, then sorted by
  # keys (each a result column position) and cut by limit / offset.
  class CompoundPlan < Plan
    attr_reader :columns

    def initialize(first, steps, columns, keys, limit, offset)
      @first = first
      @steps = steps
      @columns = columns
      @keys = keys
      @limit = limit
      @offset = offset
    end

    def rows
      combined = @first.rows
      @steps.each { |step| combined = combine(step.op, combined, step.plan.rows) }
      Limits.slice(sorted(combined), @limit, @offset)
    end

    private

    def combine(op, left, right)
      case op
      when "UNION ALL" then left + right
      when "UNION" then RowSet.distinct(left + right)
      when "INTERSECT"
        present = RowSet.keys_of(right)
        RowSet.distinct(left.select { |row| present.key?(RowSet.key(row)) })
      else
        absent = RowSet.keys_of(right)
        RowSet.distinct(left.reject { |row| absent.key?(RowSet.key(row)) })
      end
    end

    def sorted(rows)
      return rows if @keys.empty?
      candidates = rows.each_with_index.map do |row, serial|
        Candidate.new(row, @keys.map { |key| key.value(row, row) }, serial)
      end
      candidates.sort { |a, b| SortKey.compare_candidates(@keys, a, b) }.map(&:values)
    end
  end
end

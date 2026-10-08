module MiniSql
  # One ORDER BY term after name resolution: it sorts either by a result column (index)
  # or by an expression evaluated on the source row.
  class SortKey
    attr_reader :index, :expr, :descending

    # collation orders the TEXT values of the key.
    def initialize(index, expr, descending, nulls, collation)
      @index = index
      @expr = expr
      @descending = descending
      @nulls = nulls
      @collation = collation
    end

    def value(result, row)
      index = @index
      return result.fetch(index, nil) if index
      expr = @expr
      expr ? Evaluator.evaluate(expr, row) : nil
    end

    # Order of two key values: NULLs first under ASC, last under DESC, unless NULLS says otherwise.
    def compare(left, right)
      nulls_first = @nulls ? @nulls == :first : !@descending
      if left.nil? || right.nil?
        return 0 if left.nil? && right.nil?
        return left.nil? == nulls_first ? -1 : 1
      end
      order = Value.compare(left, right, @collation)
      @descending ? -order : order
    end

    # Order of two candidates by all keys, ties broken by their serial (the sort is stable).
    def self.compare_candidates(keys, left, right)
      keys.each_with_index do |key, i|
        order = key.compare(left.keys.fetch(i, nil), right.keys.fetch(i, nil))
        return order unless order.zero?
      end
      left.serial - right.serial
    end
  end

  # A row waiting to be sorted: its values, the values of its sort keys, and its position before sorting.
  class Candidate
    attr_reader :values, :keys, :serial

    def initialize(values, keys, serial)
      @values = values
      @keys = keys
      @serial = serial
    end
  end
end

module MiniSql
  # The row a recursive cte stands for while its recursive select runs (SPEC 5.2).
  class WorkingSet
    attr_accessor :rows

    def initialize
      @rows = [] # @type ivar @rows: Array[Array[sql_value]]
    end
  end

  # A recursive cte: `initial UNION [ALL] step`, where step reads the working set. Rows are taken from a queue
  # in order; each is added to the result and runs `step` with it as the only working row.
  class RecursivePlan < Plan
    attr_reader :columns

    # limit / offset are those of the cte's select (limit nil: none); they cut the result and stop the recursion.
    def initialize(initial, step, working, union_all, columns, limit, offset)
      @initial = initial
      @step = step
      @working = working
      @union_all = union_all
      @columns = columns
      @limit = limit
      @offset = offset
    end

    def rows
      result = [] # @type var result: Array[Array[sql_value]]
      queue = [] # @type var queue: Array[Array[sql_value]]
      seen = {} # @type var seen: Hash[Array[sql_value], bool]
      limit = @limit
      wanted = limit ? limit + @offset : nil
      @initial.rows.each { |row| enqueue(queue, seen, row) }
      head = 0
      while head < queue.length && (wanted.nil? || result.length < wanted)
        row = queue.fetch(head)
        head += 1
        result << row
        @working.rows = [row]
        @step.rows.each { |next_row| enqueue(queue, seen, next_row) }
      end
      Limits.slice(result, @limit, @offset)
    end

    private

    # Queues the row, unless UNION has queued an equal one before.
    def enqueue(queue, seen, row)
      unless @union_all
        key = RowSet.key(row)
        return if seen[key]
        seen[key] = true
      end
      queue << row
    end
  end
end

module MiniSql
  # One join of a FROM clause: kind is :inner or :left; condition is the bound ON (or USING) test, nil when
  # every pair joins.
  class JoinStep
    attr_reader :kind, :source, :condition

    def initialize(kind, source, condition)
      @kind = kind
      @source = source
      @condition = condition
    end
  end

  # A FROM clause after name resolution. Its rows are the joined rows: the columns of every source in order.
  class FromPlan
    # first is nil without FROM (the query then reads one empty row).
    def initialize(first, steps)
      @first = first
      @steps = steps
    end

    def rows
      first = @first
      unless first
        none = [] # @type var none: Array[sql_value]
        return [none]
      end
      joined = first.rows
      @steps.each { |step| joined = join(joined, step) }
      joined
    end

    private

    def join(left_rows, step)
      right_rows = step.source.rows
      padding = Array.new(step.source.width, nil) # @type var padding: Array[sql_value]
      condition = step.condition
      result = [] # @type var result: Array[Array[sql_value]]
      left_rows.each do |left|
        matched = false
        right_rows.each do |right|
          pair = left + right
          next unless condition.nil? || Value.truth(Evaluator.evaluate(condition, pair)) == true
          matched = true
          result << pair
        end
        result << (left + padding) if step.kind == :left && !matched
      end
      result
    end
  end
end

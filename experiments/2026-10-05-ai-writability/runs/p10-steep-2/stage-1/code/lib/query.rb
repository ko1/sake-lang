module MiniSql
  # One ORDER BY term after name resolution: it sorts either by a result column (index)
  # or by an expression evaluated on the source row.
  class SortKey
    attr_reader :index, :expr

    def initialize(index, expr, descending, nulls)
      @index = index
      @expr = expr
      @descending = descending
      @nulls = nulls
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
      order = Value.compare(left, right)
      @descending ? -order : order
    end
  end

  # An output row waiting to be sorted.
  class Candidate
    attr_reader :values, :keys, :serial

    def initialize(values, keys, serial)
      @values = values
      @keys = keys
      @serial = serial
    end
  end

  # Runs a SELECT and returns its printed lines.
  class Query
    def initialize(database, select)
      @database = database
      @select = select
    end

    def run
      from = @select.from
      table = from ? @database.fetch_table(from) : nil
      results, aliases = bind_result_columns(table)
      binder = Binder.new(table, aliases)
      condition = @select.where
      where = condition ? binder.bind(condition) : nil
      keys = sort_keys(binder, results, aliases)
      limit, offset = limit_and_offset
      source = table ? table.rows : [no_row]
      rows = source.select { |row| where.nil? || Value.truth(Evaluator.evaluate(where, row)) == true }
      candidates = rows.each_with_index.map do |row, serial|
        values = results.map { |expr| Evaluator.evaluate(expr, row) }
        Candidate.new(values, keys.map { |key| key.value(values, row) }, serial)
      end
      candidates.sort! { |a, b| compare(keys, a, b) } unless keys.empty?
      window(candidates, limit, offset).map { |c| c.values.map { |v| Value.render(v) }.join("|") }
    end

    private

    # The single empty row a SELECT without FROM reads.
    def no_row
      row = [] # @type var row: Array[sql_value]
      row
    end

    # The bound result expressions, and the aliases among them (lower-case name => expression).
    def bind_result_columns(table)
      binder = Binder.new(table, {})
      results = [] # @type var results: Array[Expr]
      aliases = {} # @type var aliases: Hash[String, Expr]
      @select.columns.each do |column|
        expr = column.expr
        if expr
          bound = binder.bind(expr)
          alias_name = column.alias_name
          aliases[alias_name.downcase(:ascii)] = bound if alias_name
          results << bound
        else
          raise SqlError, "no tables specified" unless table
          table.columns.each_with_index { |col, i| results << BoundColumn.new(i, col.type) }
        end
      end
      [results, aliases]
    end

    def sort_keys(binder, results, aliases)
      @select.order_by.each_with_index.map do |term, position|
        ordinal = ordinal_of(term.expr)
        if ordinal
          unless ordinal.between?(1, results.length)
            raise SqlError, "#{nth(position + 1)} ORDER BY term out of range - should be between 1 and #{results.length}"
          end
          SortKey.new(ordinal - 1, nil, term.descending, term.nulls)
        else
          alias_index = alias_position(term.expr, results, aliases)
          expr = alias_index ? nil : binder.bind(term.expr)
          SortKey.new(alias_index, expr, term.descending, term.nulls)
        end
      end
    end

    # k for an integer literal k or `-k`, else nil.
    def ordinal_of(expr)
      if expr.is_a?(Literal) && expr.value.is_a?(Integer)
        expr.value
      elsif expr.is_a?(Unary) && expr.op == "-"
        inner = ordinal_of(expr.operand)
        inner ? -inner : nil
      end
    end

    # The result column a bare name stands for, if the name is an alias.
    def alias_position(expr, results, aliases)
      return nil unless expr.is_a?(ColumnRef) && expr.qualifier.nil?
      target = aliases[expr.name.downcase(:ascii)]
      target ? results.index { |result| result.equal?(target) } : nil
    end

    def nth(number)
      suffix =
        if (11..13).cover?(number % 100) then "th"
        else { 1 => "st", 2 => "nd", 3 => "rd" }.fetch(number % 10, "th")
        end
      "#{number}#{suffix}"
    end

    def compare(keys, left, right)
      keys.each_with_index do |key, i|
        order = key.compare(left.keys.fetch(i, nil), right.keys.fetch(i, nil))
        return order unless order.zero?
      end
      left.serial <=> right.serial
    end

    # LIMIT and OFFSET as integers: nil limit means no limit; offset is at least 0.
    def limit_and_offset
      binder = Binder.new(nil, {})
      limit = integer_of(@select.limit, binder)
      offset = integer_of(@select.offset, binder)
      [limit && limit >= 0 ? limit : nil, offset && offset > 0 ? offset : 0]
    end

    def integer_of(expr, binder)
      return nil unless expr
      value = Evaluator.evaluate(binder.bind(expr), [])
      case value
      when Integer then value
      when Float then value.to_i
      when String then Value.to_number(value).to_i
      end
    end

    def window(candidates, limit, offset)
      rest = candidates.drop(offset)
      limit ? rest.first(limit) : rest
    end
  end
end

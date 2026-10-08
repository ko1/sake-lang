module MiniSql
  # Resolves the names of a SELECT (SPEC 1.7, 3.3) and builds its QueryPlan, raising SqlError
  # for every name or clause error before any row is read.
  class Planner
    def initialize(database, select)
      @database = database
      @select = select
    end

    def plan
      from = @select.from
      table = from ? @database.fetch_table(from) : nil
      scope = AggregateScope.new(table ? table.columns.length : 0)
      results, aliases = bind_result_columns(table, scope)
      aggregate = !@select.group_by.empty? || !scope.empty?
      where = bind_where(table, aliases)
      group_by = bind_group_by(table, results, aliases)
      having = bind_having(table, aliases, scope, aggregate)
      keys = sort_keys(order_binder(table, aliases, scope, aggregate), results, aliases)
      limit, offset = limit_and_offset
      QueryPlan.new(table, results, where, group_by, having, aggregate ? scope : nil, @select.distinct, keys, limit, offset)
    end

    private

    # The bound result expressions, and the aliases among them (lower-case name => expression).
    def bind_result_columns(table, scope)
      binder = Binder.new(table, {}, scope: scope)
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

    def bind_where(table, aliases)
      condition = @select.where
      condition ? Binder.new(table, aliases).bind(condition) : nil
    end

    # GROUP BY terms: an integer k means the k-th result column; else an expression on the row.
    def bind_group_by(table, results, aliases)
      binder = Binder.new(table, aliases, refusal: :group_by)
      @select.group_by.each_with_index.map do |term, position|
        ordinal = ordinal_of(term)
        next binder.bind(term) unless ordinal
        unless ordinal.between?(1, results.length)
          raise SqlError, "#{nth(position + 1)} GROUP BY term out of range - should be between 1 and #{results.length}"
        end
        result = results.fetch(ordinal - 1)
        if result.aggregate_name
          raise SqlError, "aggregate functions are not allowed in the GROUP BY clause"
        end
        result
      end
    end

    def bind_having(table, aliases, scope, aggregate)
      condition = @select.having
      return nil unless condition
      raise SqlError, "HAVING clause on a non-aggregate query" unless aggregate
      Binder.new(table, aliases, scope: scope).bind(condition)
    end

    # ORDER BY sees aggregates only in an aggregate query.
    def order_binder(table, aliases, scope, aggregate)
      aggregate ? Binder.new(table, aliases, scope: scope) : Binder.new(table, aliases, refusal: :order_by)
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
  end
end

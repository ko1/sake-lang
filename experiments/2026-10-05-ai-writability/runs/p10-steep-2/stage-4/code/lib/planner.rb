module MiniSql
  # Resolves the names of a SELECT (SPEC 1.7, 3.3) and builds its QueryPlan, raising SqlError
  # for every name or clause error before any row is read.
  class Planner
    # outer: the enclosing queries when the select is a subquery of an expression, else nil.
    def initialize(database, select, outer)
      @database = database
      @select = select
      @environment = Environment.new(database, RowFrame.new, outer)
    end

    def plan
      sources = Sources.new
      from = bind_from(sources)
      aggregates = AggregateScope.new(sources.width)
      results, columns, aliases = bind_result_columns(sources, aggregates)
      aggregate = !@select.group_by.empty? || !aggregates.empty?
      where = bind_where(sources, aliases)
      group_by = bind_group_by(sources, results, aliases)
      having = bind_having(sources, aliases, aggregates, aggregate)
      keys = sort_keys(order_binder(sources, aliases, aggregates, aggregate), results, aliases)
      limit, offset = limit_and_offset
      QueryPlan.new(from, results, columns, where, group_by, having, aggregate ? aggregates : nil, @select.distinct, keys,
                    limit, offset)
    end

    private

    # Adds the sources of FROM to `sources` and binds the join conditions (SPEC 4.1).
    def bind_from(sources)
      clause = @select.from
      return FromPlan.new(nil, []) unless clause
      first = add_source(clause.first, sources)
      FromPlan.new(first, clause.joins.map { |join| join_step(join, sources) })
    end

    def add_source(item, sources)
      source =
        case item
        when TableRef then TableSource.new(item.alias_name || item.name, @database.fetch_table(item.name), sources.width)
        when SubqueryRef then DerivedSource.new(item.alias_name, Planner.new(@database, item.select, nil).plan, sources.width)
        else raise ArgumentError, "unknown from-item"
        end
      sources.add(source)
      source
    end

    def join_step(join, sources)
      source = add_source(join.item, sources)
      on = join.on
      using = join.using
      condition =
        if on then Binder.new(sources, {}, @environment).bind(on)
        elsif using then using_condition(using, source, sources)
        end
      JoinStep.new(join.kind, source, condition)
    end

    # `USING (c, ...)` is `ON left.c = right.c AND ...`; the right copy of c is hidden from `*` and bare names.
    def using_condition(names, source, sources)
      condition = nil # @type var condition: Expr?
      names.each do |name|
        left = sources.first_index(name)
        right = source.index_of(name)
        unless left && right && left < right
          raise SqlError, "cannot join using column #{name} - column not present in both tables"
        end
        left_affinity = sources.affinity_at(left)
        right_affinity = sources.affinity_at(right)
        test = Compare.new("=", BoundColumn.new(left, left_affinity), BoundColumn.new(right, right_affinity),
                           left_affinity, right_affinity)
        sources.hide(right)
        condition = condition ? Binary.new("AND", condition, test) : test
      end
      condition
    end

    # The bound result expressions, their descriptions, and the aliases among them (lower-case name => expression).
    def bind_result_columns(sources, aggregates)
      binder = Binder.new(sources, {}, @environment, aggregates: aggregates)
      results = [] # @type var results: Array[Expr]
      columns = [] # @type var columns: Array[SourceColumn]
      aliases = {} # @type var aliases: Hash[String, Expr]
      @select.columns.each do |column|
        expr = column.expr
        if expr
          bound = binder.bind(expr)
          alias_name = column.alias_name
          aliases[alias_name.downcase(:ascii)] = bound if alias_name
          results << bound
          plain_name = expr.is_a?(ColumnRef) ? expr.name : nil
          columns << SourceColumn.new(alias_name || plain_name, bound.affinity)
        else
          qualifier = column.star_qualifier
          raise SqlError, "no tables specified" if qualifier.nil? && sources.empty?
          sources.expand(qualifier).each do |index, source_column|
            results << BoundColumn.new(index, source_column.affinity)
            columns << source_column
          end
        end
      end
      [results, columns, aliases]
    end

    def bind_where(sources, aliases)
      condition = @select.where
      condition ? Binder.new(sources, aliases, @environment).bind(condition) : nil
    end

    # GROUP BY terms: an integer k means the k-th result column; else an expression on the row.
    def bind_group_by(sources, results, aliases)
      binder = Binder.new(sources, aliases, @environment, refusal: :group_by)
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

    def bind_having(sources, aliases, aggregates, aggregate)
      condition = @select.having
      return nil unless condition
      raise SqlError, "HAVING clause on a non-aggregate query" unless aggregate
      Binder.new(sources, aliases, @environment, aggregates: aggregates).bind(condition)
    end

    # ORDER BY sees aggregates only in an aggregate query.
    def order_binder(sources, aliases, aggregates, aggregate)
      if aggregate
        Binder.new(sources, aliases, @environment, aggregates: aggregates)
      else
        Binder.new(sources, aliases, @environment, refusal: :order_by)
      end
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
      binder = Binder.new(Sources.new, {}, @environment)
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

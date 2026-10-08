module MiniSql
  # Resolves the names of a simple SELECT (SPEC 1.7, 3.3) and builds its QueryPlan, raising SqlError
  # for every name or clause error before any row is read.
  class SimplePlanner
    # outer: the enclosing queries when the select is a subquery of an expression, else nil; ctes: the
    # WITH tables it can see, else nil.
    def initialize(database, select, outer, ctes)
      @database = database
      @select = select
      @environment = Environment.new(database, RowFrame.new, outer, ctes)
    end

    def plan
      sources = Sources.new
      from = bind_from(sources)
      aggregates = AggregateScope.new(sources.width)
      windows = WindowScope.new(@select.windows)
      results, columns, aliases = bind_result_columns(sources, aggregates, windows)
      aggregate = !@select.group_by.empty? || !aggregates.empty?
      where = bind_where(sources, aliases)
      group_by = bind_group_by(sources, results, aliases)
      having = bind_having(sources, aliases, aggregates, aggregate)
      keys = sort_keys(order_binder(sources, aliases, aggregates, windows, aggregate), results, aliases)
      windows.place(sources.width + (aggregate ? aggregates.specs.length : 0))
      limit, offset = Limits.resolve(@select.limit, @select.offset, @environment)
      QueryPlan.new(from, results, columns, where, group_by, having, aggregate ? aggregates : nil, windows,
                    @select.distinct, keys, limit, offset)
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
        when TableRef then named_source(item, sources.width)
        when SubqueryRef then subquery_source(item, sources.width)
        else raise ArgumentError, "unknown from-item"
        end
      sources.add(source)
      source
    end

    # A table name in FROM: a cte of that name, else a view, else a table.
    def named_source(item, offset)
      label = item.alias_name || item.name
      ctes = @environment.ctes
      cte = ctes && ctes.find(item.name)
      return cte.source(label, offset) if cte
      view = @database.find_view(item.name)
      return view_source(view, label, offset) if view
      TableSource.new(label, @database.fetch_table(item.name), offset)
    end

    # A view runs its select anew each time it is used.
    def view_source(view, label, offset)
      plan = Planner.new(@database, view.select, nil, nil).plan
      DerivedSource.new(label, plan, offset, SourceColumn.rename(plan.columns, view.columns))
    end

    def subquery_source(item, offset)
      plan = Planner.new(@database, item.select, nil, @environment.ctes).plan
      DerivedSource.new(item.alias_name, plan, offset, plan.columns)
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
        left_column = sources.column_at(left)
        right_column = sources.column_at(right)
        left_ref = BoundColumn.new(left, left_column&.affinity, left_column&.source_collation || :binary)
        right_ref = BoundColumn.new(right, right_column&.affinity, right_column&.source_collation || :binary)
        test = Compare.new("=", left_ref, right_ref, left_ref.affinity, right_ref.affinity,
                           Collation.of_exprs(left_ref, right_ref))
        sources.hide(right)
        condition = condition ? Binary.new("AND", condition, test) : test
      end
      condition
    end

    # The bound result expressions, their descriptions, and the aliases among them (lower-case name => expression).
    def bind_result_columns(sources, aggregates, windows)
      binder = Binder.new(sources, {}, @environment, aggregates: aggregates, windows: windows)
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
          columns << SourceColumn.of(alias_name || plain_name, bound)
        else
          qualifier = column.star_qualifier
          raise SqlError, "no tables specified" if qualifier.nil? && sources.empty?
          sources.expand(qualifier).each do |index, source_column|
            results << BoundColumn.new(index, source_column.affinity, source_column.source_collation)
            columns << SourceColumn.new(source_column.name, source_column.affinity, source_column.source_collation, false)
          end
        end
      end
      [results, columns, aliases]
    end

    def bind_where(sources, aliases)
      condition = @select.where
      condition ? Binder.new(sources, aliases, @environment).bind(condition) : nil
    end

    # GROUP BY terms: an integer k means the k-th result column (`k COLLATE n` that column under n); else an
    # expression on the row.
    def bind_group_by(sources, results, aliases)
      binder = Binder.new(sources, aliases, @environment, refusal: :group_by)
      @select.group_by.each_with_index.map do |term, position|
        inner, written = Terms.split_collate(term)
        ordinal = Terms.ordinal(inner)
        next binder.bind(term) unless ordinal
        Terms.check_ordinal(ordinal, position, "GROUP BY", results.length)
        result = results.fetch(ordinal - 1)
        if result.aggregate_name
          raise SqlError, "aggregate functions are not allowed in the GROUP BY clause"
        end
        window = result.window_name
        raise SqlError, "misuse of window function #{window}()" if window
        written ? Collated.new(result, Collation.lookup(written)) : result
      end
    end

    def bind_having(sources, aliases, aggregates, aggregate)
      condition = @select.having
      return nil unless condition
      raise SqlError, "HAVING clause on a non-aggregate query" unless aggregate
      Binder.new(sources, aliases, @environment, aggregates: aggregates).bind(condition)
    end

    # ORDER BY sees aggregates only in an aggregate query, and window calls always.
    def order_binder(sources, aliases, aggregates, windows, aggregate)
      if aggregate
        Binder.new(sources, aliases, @environment, aggregates: aggregates, windows: windows)
      else
        Binder.new(sources, aliases, @environment, windows: windows, refusal: :order_by)
      end
    end

    def sort_keys(binder, results, aliases)
      @select.order_by.each_with_index.map do |term, position|
        inner, written = Terms.split_collate(term.expr)
        explicit = written && Collation.lookup(written)
        ordinal = Terms.ordinal(inner)
        Terms.check_ordinal(ordinal, position, "ORDER BY", results.length) if ordinal
        alias_index = ordinal ? ordinal - 1 : alias_position(inner, results, aliases)
        if alias_index
          # A term standing for a result column sorts under that column's collation unless it has its own.
          SortKey.new(alias_index, nil, term.descending, term.nulls, explicit || results.fetch(alias_index).collation)
        else
          bound = binder.bind(inner)
          SortKey.new(nil, bound, term.descending, term.nulls, explicit || bound.collation)
        end
      end
    end

    # The result column a bare name stands for, if the name is an alias.
    def alias_position(expr, results, aliases)
      return nil unless expr.is_a?(ColumnRef) && expr.qualifier.nil?
      target = aliases[expr.name.downcase(:ascii)]
      target ? results.index { |result| result.equal?(target) } : nil
    end
  end
end

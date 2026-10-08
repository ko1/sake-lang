# frozen_string_literal: true

require_relative "aggregates"
require_relative "ast"
require_relative "binder"
require_relative "collation"
require_relative "errors"
require_relative "evaluator"
require_relative "from_clause"
require_relative "grouping"
require_relative "limits"
require_relative "ordering"
require_relative "scope"
require_relative "values"
require_relative "window_functions"
require_relative "windows"

module Sql
  # A SELECT. Planning (`new`) binds all names first, so name errors happen before any row is read;
  # `run` then joins the sources, filters, groups (aggregate queries), computes window calls, projects,
  # removes duplicates, sorts and slices, and returns the result rows (arrays of values).
  #
  # The row that result columns, HAVING and ORDER BY are evaluated on is: the sources' values (and the
  # enclosing query's row), then one slot per window call (WindowRef), then one per aggregate (AggRef).
  class Query
    # name: the column's name for a subquery in FROM (nil if it has none).
    BoundColumn = Data.define(:expr, :alias, :name)

    GROUP_BY_SCOPE_AGGREGATES = Aggregates::Forbidden.new("aggregate functions are not allowed in the GROUP BY clause")
    PLAIN_ORDER_BY_AGGREGATES = Aggregates::Forbidden.new("misuse of aggregate: %s()")

    # planner: the Planner that plans this and the queries it contains (and resolves its table names);
    # parent: the Scope of the enclosing query when this is a subquery in an expression.
    def initialize(planner, select, parent = nil)
      @select = select
      @from = FromClause.new(select.from, planner, parent)
      base = @from.scope
      @own_width = base.width
      definitions = Windows::Definitions.new(select.windows)
      window_count = Windows.calls_in(plain_exprs(select)).length
      windows = Windows::Collector.new(base.row_width, definitions)
      collector = Aggregates::Collector.new(base.row_width + window_count)
      @columns = bind_result_columns(base, collector, windows)
      @aggregate = !select.group_by.nil? || select.columns.any? { |rc| aggregate_column?(rc.expr, definitions) }
      @where = select.where && Binder.bind(select.where, alias_scope(base, @columns))
      @group_by = bind_group_by(base, @columns)
      @having = bind_having(base, @columns, collector)
      @keys = bind_order_by(base, @columns, @aggregate ? collector : PLAIN_ORDER_BY_AGGREGATES, windows)
      @limit = select.limit && Binder.bind(select.limit, base.with(aliases: {}))
      @offset = select.offset && Binder.bind(select.offset, base.with(aliases: {}))
      @specs = collector.specs
      @window_calls = windows.calls
      @window_offset = base.row_width
      raise "window slots miscounted" unless @window_calls.length == window_count
      @cache = nil
    end

    # Can two runs in one statement give different rows (it uses the enclosing row, or a recursive cte's
    # working row)? If not, the rows are computed once.
    def volatile?
      @from.volatile?
    end

    # The result columns as sources see them: name (alias, or a plain column's name), affinity type and
    # collation (7.5: that of the column's expression, BINARY if it has none).
    def result_columns
      @columns.map do |c|
        SourceColumn.new(c.name, c.expr.is_a?(ColumnRef) ? c.expr.type : nil, Collation.of(c.expr))
      end
    end

    # Per result column: nil if its expression has no collation, else [name, explicit?] (see Collation.info).
    def result_collation_infos
      @columns.map { |c| Collation.info(c.expr) }
    end

    # The result rows. `outer_row` is the row of the enclosing query (for a correlated subquery); a
    # query that uses no outer name gives the same rows every time, so they are computed once.
    def run(outer_row = [])
      return execute(outer_row) if volatile?
      @cache ||= execute(outer_row)
    end

    private

    def execute(outer_row)
      limit = Limits.count(@limit, @from.scope.row_width)
      offset = Limits.count(@offset, @from.scope.row_width)
      rows = @from.rows(outer_row)
      rows = rows.select { |row| Values.truth(Evaluator.evaluate(@where, row)) } if @where
      if @aggregate
        rows = group_rows(rows, outer_row)
      elsif !@window_calls.empty?
        rows = rows.map { |row| row + Array.new(@window_calls.length) }
      end
      WindowFunctions.apply(rows, @window_calls, @window_offset) unless @window_calls.empty?
      entries = rows.map { |row| [@columns.map { |c| Evaluator.evaluate(c.expr, row) }, row] }
      entries = distinct(entries) if @select.distinct
      entries = sort(entries, @keys) unless @keys.empty?
      Limits.slice(entries.map(&:first), limit, offset)
    end

    # The expressions of the result columns and the ORDER BY terms: where window calls may be.
    def plain_exprs(select)
      select.columns.map(&:expr).reject { |e| e.is_a?(Star) || e.is_a?(TableStar) } + select.order_by.map(&:expr)
    end

    # Does a result column make this an aggregate query: an aggregate call, or a window call that has one
    # in its window-spec (arguments are found like any call's)?
    def aggregate_column?(expr, definitions)
      return true if Aggregates.contains_call?(expr)
      Windows.calls_in([expr]).any? do |call|
        spec = definitions.resolve(call.over)
        (spec.partition_by + spec.order_by.map(&:expr)).any? { |e| Aggregates.contains_call?(e) }
      end
    end

    def bind_result_columns(base, collector, windows)
      scope = base.with(aggregates: collector, windows: windows)
      @select.columns.flat_map do |rc|
        case rc.expr
        when Star
          raise SqlError, "no tables specified" if base.sources.empty?
          base.sources.flat_map { |source| expand(source, base) }
        when TableStar
          source = base.source_named(rc.expr.table) or raise SqlError, "no such table: #{rc.expr.table}"
          expand(source, nil)
        else
          [BoundColumn.new(Binder.bind(rc.expr, scope), rc.alias, rc.alias || (rc.expr.name if rc.expr.is_a?(Column)))]
        end
      end
    end

    # `*` / `q.*` for one source; `*` (scope given) leaves out the columns USING merged away.
    def expand(source, scope)
      source.columns.each_with_index.filter_map do |c, i|
        next if scope && !scope.visible?(source.offset + i)
        BoundColumn.new(ColumnRef.new(source.offset + i, c.type, c.collation), nil, c.name)
      end
    end

    def alias_scope(base, columns, aggregates = Scope::NO_AGGREGATES, windows = Windows::FORBIDDEN)
      aliases = {}
      columns.each { |c| aliases[Sql.fold(c.alias)] ||= c.expr if c.alias }
      base.with(aliases: aliases, aggregates: aggregates, windows: windows)
    end

    # Bound GROUP BY terms, or nil without GROUP BY.
    def bind_group_by(base, columns)
      return nil unless @select.group_by
      scope = alias_scope(base, columns, GROUP_BY_SCOPE_AGGREGATES)
      @select.group_by.each_with_index.map do |term, i|
        expr, collate = Ordering.split_collate(term)
        index = Ordering.ordinal(expr, i, columns.length, "GROUP BY")
        if index
          GROUP_BY_SCOPE_AGGREGATES.check_alias(columns[index].expr)
          collate ? Collate.new(columns[index].expr, Collation.lookup(collate)) : columns[index].expr
        else
          Binder.bind(term, scope)
        end
      end
    end

    def bind_having(base, columns, collector)
      return nil unless @select.having
      raise SqlError, "HAVING clause on a non-aggregate query" unless @aggregate
      Binder.bind(@select.having, alias_scope(base, columns, collector))
    end

    def bind_order_by(base, columns, aggregates, windows)
      scope = alias_scope(base, columns, aggregates, windows)
      @select.order_by.each_with_index.map do |term, i|
        expr, collate = Ordering.split_collate(term.expr)
        index = Ordering.ordinal(expr, i, columns.length, "ORDER BY") || alias_index(expr, columns)
        if index
          # a term standing for a result column sorts under that column's collation unless it names one
          collation = collate ? Collation.lookup(collate) : Collation.of(columns[index].expr)
          Ordering::SortKey.new(index, nil, term.desc, term.nulls, collation)
        else
          bound = Binder.bind(term.expr, scope)
          Ordering::SortKey.new(nil, bound, term.desc, term.nulls, Collation.of(bound))
        end
      end
    end

    # A term that is just a name equal to a result column's alias means that result column.
    def alias_index(expr, columns)
      return nil unless expr.is_a?(Column) && expr.table.nil?
      key = Sql.fold(expr.name)
      columns.index { |c| c.alias && Sql.fold(c.alias) == key }
    end

    # One group row (see Grouping) per group that HAVING keeps.
    def group_rows(rows, outer_row)
      empty_row = Array.new(@own_width) + outer_row
      group_rows = Grouping.partition(rows, @group_by).map { |group| Grouping.group_row(group, @specs, empty_row, @window_calls.length) }
      @having ? group_rows.select { |row| Values.truth(Evaluator.evaluate(@having, row)) } : group_rows
    end

    # Keeps the first of each set of entries with equal result rows (3.4), each column under its own collation.
    def distinct(entries)
      collations = @columns.map { |c| Collation.of(c.expr) }
      entries.uniq { |result, _| Values.row_key(result, collations) }
    end

    def sort(entries, keys)
      Ordering.sort(entries, keys) do |(result, row), key|
        key.result_index ? result[key.result_index] : Evaluator.evaluate(key.expr, row)
      end
    end
  end
end

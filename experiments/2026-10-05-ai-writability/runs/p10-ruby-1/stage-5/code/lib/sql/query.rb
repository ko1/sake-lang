# frozen_string_literal: true

require_relative "aggregates"
require_relative "ast"
require_relative "binder"
require_relative "errors"
require_relative "evaluator"
require_relative "from_clause"
require_relative "grouping"
require_relative "limits"
require_relative "ordering"
require_relative "scope"
require_relative "values"

module Sql
  # A SELECT. Planning (`new`) binds all names first, so name errors happen before any row is read;
  # `run` then joins the sources, filters, groups (aggregate queries), projects, removes duplicates,
  # sorts and slices, and returns the result rows (arrays of values).
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
      collector = Aggregates::Collector.new(base.row_width)
      @columns = bind_result_columns(base, collector)
      @aggregate = !select.group_by.nil? || select.columns.any? { |rc| Aggregates.contains_call?(rc.expr) }
      @where = select.where && Binder.bind(select.where, alias_scope(base, @columns))
      @group_by = bind_group_by(base, @columns)
      @having = bind_having(base, @columns, collector)
      @keys = bind_order_by(base, @columns, @aggregate ? collector : PLAIN_ORDER_BY_AGGREGATES)
      @limit = select.limit && Binder.bind(select.limit, base.with(aliases: {}))
      @offset = select.offset && Binder.bind(select.offset, base.with(aliases: {}))
      @specs = collector.specs
      @cache = nil
    end

    # Can two runs in one statement give different rows (it uses the enclosing row, or a recursive cte's
    # working row)? If not, the rows are computed once.
    def volatile?
      @from.volatile?
    end

    # The result columns as sources see them: name (alias, or a plain column's name) and affinity type.
    def result_columns
      @columns.map { |c| SourceColumn.new(c.name, c.expr.is_a?(ColumnRef) ? c.expr.type : nil) }
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
      rows = group_rows(rows, outer_row) if @aggregate
      entries = rows.map { |row| [@columns.map { |c| Evaluator.evaluate(c.expr, row) }, row] }
      entries = distinct(entries) if @select.distinct
      entries = sort(entries, @keys) unless @keys.empty?
      Limits.slice(entries.map(&:first), limit, offset)
    end

    def bind_result_columns(base, collector)
      scope = base.with(aggregates: collector)
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
        BoundColumn.new(ColumnRef.new(source.offset + i, c.type), nil, c.name)
      end
    end

    def alias_scope(base, columns, aggregates = Scope::NO_AGGREGATES)
      aliases = {}
      columns.each { |c| aliases[Sql.fold(c.alias)] ||= c.expr if c.alias }
      base.with(aliases: aliases, aggregates: aggregates)
    end

    # Bound GROUP BY terms, or nil without GROUP BY.
    def bind_group_by(base, columns)
      return nil unless @select.group_by
      scope = alias_scope(base, columns, GROUP_BY_SCOPE_AGGREGATES)
      @select.group_by.each_with_index.map do |expr, i|
        index = Ordering.ordinal(expr, i, columns.length, "GROUP BY")
        if index
          GROUP_BY_SCOPE_AGGREGATES.check_alias(columns[index].expr)
          columns[index].expr
        else
          Binder.bind(expr, scope)
        end
      end
    end

    def bind_having(base, columns, collector)
      return nil unless @select.having
      raise SqlError, "HAVING clause on a non-aggregate query" unless @aggregate
      Binder.bind(@select.having, alias_scope(base, columns, collector))
    end

    def bind_order_by(base, columns, aggregates)
      scope = alias_scope(base, columns, aggregates)
      @select.order_by.each_with_index.map do |term, i|
        expr = term.expr
        index = Ordering.ordinal(expr, i, columns.length, "ORDER BY") || alias_index(expr, columns)
        bound = index ? nil : Binder.bind(expr, scope)
        Ordering::SortKey.new(index, bound, term.desc, term.nulls)
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
      group_rows = Grouping.partition(rows, @group_by).map { |group| Grouping.group_row(group, @specs, empty_row) }
      @having ? group_rows.select { |row| Values.truth(Evaluator.evaluate(@having, row)) } : group_rows
    end

    # Keeps the first of each set of entries with equal result rows (3.4).
    def distinct(entries)
      entries.uniq { |result, _| Values.row_key(result) }
    end

    def sort(entries, keys)
      Ordering.sort(entries, keys) do |(result, row), key|
        key.result_index ? result[key.result_index] : Evaluator.evaluate(key.expr, row)
      end
    end
  end
end

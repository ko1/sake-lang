# frozen_string_literal: true

require_relative 'aggregate_functions'
require_relative 'aggregates'
require_relative 'collation'
require_relative 'ast'
require_relative 'compiler'
require_relative 'errors'
require_relative 'from_clause'
require_relative 'limits'
require_relative 'ordering'
require_relative 'query'
require_relative 'scope'
require_relative 'values'
require_relative 'window_calculation'
require_relative 'windows'

module SQL
  # Plans and runs one SELECT (SPEC 1.7, 3.x, 4.x, 6.x): compiles every expression first (so name errors come
  # before any row is read), then filters, groups, computes window calls, projects, de-duplicates, sorts
  # and limits.
  #
  # In an aggregate query the rows that HAVING, the result columns and ORDER BY see are "group
  # rows": a joined row of the FROM clause (for bare columns) followed by one slot per aggregate call.
  #
  # The values of the window calls (6.2) follow in the same way, one slot per call, after the aggregates.
  #
  # `parent` is the Scope of the clause that contains this query when it is a subquery (4.3).
  class SelectQuery
    include Query

    def initialize(stmt, namespace, parent: nil)
      @stmt = stmt
      @namespace = namespace
      @correlation = Correlation.new(false)
      @from = stmt.from && FromClause.new(stmt.from, namespace, parent, @correlation)
      @level = @from ? @from.level : Level.new([], namespace, parent:, correlation: @correlation)
      @columns = expand_result_columns # [[expr, alias]]
      @aliases = @columns.filter_map { |expr, al| [al.downcase, expr] if al }.to_h
      @calls = collect_aggregate_calls
      @window_definitions = Windows.resolve_definitions(stmt.windows)
      @window_calls = Windows.find_calls([@columns.map(&:first), @stmt.order_by.map(&:expr)])
      @aggregate_query = !@stmt.group_by.empty? || @columns.any? { |expr, _| !Aggregates.find_calls(expr).empty? }
      plan
    end

    # The result rows, as arrays of values.
    def rows
      rows = @from ? @from.rows : [[]]
      rows = rows.select { |row| Values.truth(@where.call(row)) } if @where
      rows = group_rows(rows) if @aggregate_query
      rows = with_window_values(rows)
      Limits.window(project(rows), @limit, @offset)
    end

    # Does a name in this query refer to a query around it, so it must run again for each row?
    def correlated? = @correlation.flag

    # Per result column: its name (alias, or a plain column's name; else nil) and its affinity (1.9).
    def result_names
      @columns.map { |expr, al| al || (expr.name if expr.is_a?(ColumnRef) || expr.is_a?(ResolvedColumn)) }
    end

    def affinities = @compiled_columns.map(&:affinity)

    # Per result column: the collation of its expression, a Collation::Info or nil (7.4).
    def collations = @compiled_columns.map(&:collation)

    private

    # --- planning -----------------------------------------------------------------------

    def plan
      raise SqlError, 'HAVING clause on a non-aggregate query' if @stmt.having && !@aggregate_query

      @aggregates = @aggregate_query ? build_aggregates : []
      slots = @aggregates.each_index.to_h { |i| [Aggregates.key(@calls[i]), row_width + i] }
      aggregate_slots = @aggregate_query ? slots : nil
      window_slots = @window_calls.each_with_index.to_h { |c, i| [Windows.key(c), row_width + @aggregates.size + i] }
      scope = Scope.new(@level, {}, aggregates: aggregate_slots, windows: window_slots)
      @calculations = build_window_calculations(aggregate_slots)
      @compiled_columns = @columns.map { |expr, _| Compiler.new(scope).compile(expr) }
      @projection = @compiled_columns.map(&:fn)
      @column_collations = @compiled_columns.map { |c| Collation.name_of(c.collation) }
      @where = @stmt.where && Compiler.new(Scope.new(@level, @aliases)).compile(@stmt.where).fn
      @group_terms = @stmt.group_by.each_with_index.map { |t, i| compile_group_term(t, i) }
      @having = @stmt.having && Compiler.new(Scope.new(@level, @aliases, aggregates: slots)).compile(@stmt.having).fn
      order_scope = Scope.new(@level, @aliases, aggregates: aggregate_slots, windows: window_slots, misuse: :plain)
      @order_terms = @stmt.order_by.each_with_index.map { |t, i| compile_order_term(t, i, order_scope) }
      @limit, @offset = limit_and_offset
      @bare_from = bare_column_aggregate
    end

    def row_width = @level.width

    # `*` becomes one column per source column (without the right copy of a USING column),
    # `q.*` the columns of source q.
    def expand_result_columns
      @stmt.items.flat_map do |item|
        next [[item.expr, item.alias]] unless item.is_a?(Star)

        sources =
          if item.table
            [@level.source_named(item.table) || raise(SqlError, "no such table: #{item.table}")]
          else
            raise SqlError, 'no tables specified' if @level.sources.empty?

            @level.sources
          end
        sources.flat_map { |s| star_columns(s, keep_hidden: !item.table.nil?) }
      end
    end

    def star_columns(source, keep_hidden:)
      source.columns.each_with_index.filter_map do |c, i|
        [ResolvedColumn.new(source.offset + i, c.name, c.affinity, c.collation), nil] if keep_hidden || !c.hidden
      end
    end

    # Aggregate calls of the result columns, HAVING and ORDER BY, each distinct one once.
    def collect_aggregate_calls
      parts = [@columns.map(&:first), @stmt.having, @stmt.order_by.map(&:expr)]
      Aggregates.find_calls(parts)
    end

    def build_aggregates
      compiler = Compiler.new(Scope.new(@level))
      @calls.map { |call| Aggregate.new(call, compiler) }
    end

    # Window expressions see the rows as the result columns do, but no window calls (6.2).
    def build_window_calculations(aggregate_slots)
      compiler = Compiler.new(Scope.new(@level, {}, aggregates: aggregate_slots))
      @window_calls.map do |call|
        WindowCalculation.new(call, Windows.resolve(call.window, @window_definitions), compiler)
      end
    end

    # The aggregate whose row supplies bare columns: the only call, when it is min/max (3.3).
    def bare_column_aggregate
      return nil unless @aggregates.size == 1 && %w[min max].include?(@aggregates[0].name)

      @aggregates[0]
    end

    # [function, collation name] of a GROUP BY term: the values are grouped under the term's collation (7.4).
    def compile_group_term(term, position)
      inner, written = Collation.split_term(term)
      expr =
        if (k = Limits.ordinal(inner))
          column = @columns.fetch(Limits.ordinal_index(k, position, 'GROUP', width)).first
          written ? Collate.new(column, written) : column
        else
          term
        end
      compiled = Compiler.new(Scope.new(@level, @aliases, misuse: :group_by)).compile(expr)
      [compiled.fn, Collation.name_of(compiled.collation)]
    end

    # A term naming a result column (by number or alias) has that column's collation unless it has its own.
    def compile_order_term(term, position, scope)
      expr, written = Collation.split_term(term.expr)
      explicit = written && Collation.lookup(written)
      index = fn = collation = nil
      if (k = Limits.ordinal(expr))
        index = Limits.ordinal_index(k, position, 'ORDER', width)
      elsif expr.is_a?(ColumnRef) && expr.table.nil? && (i = @columns.index { |_, al| al&.casecmp?(expr.name) })
        index = i
      else
        compiled = Compiler.new(scope).compile(term.expr)
        fn = compiled.fn
        collation = Collation.name_of(compiled.collation)
      end
      collation = explicit || @column_collations[index] if index
      Ordering::Term.new(term.desc, term.nulls, index, fn, collation)
    end

    def limit_and_offset = Limits.resolve(@stmt.limit, @stmt.offset, @namespace)

    # --- running ------------------------------------------------------------------------

    # The group rows (3.3) that pass HAVING, one per group.
    def group_rows(rows)
      groups =
        if @group_terms.empty?
          [rows]
        else
          rows.group_by { |row| @group_terms.map { |f, collation| Values.group_key(f.call(row), collation) } }.values
        end
      group_rows = groups.map { |group| group_row(group) }
      @having ? group_rows.select { |r| Values.truth(@having.call(r)) } : group_rows
    end

    def group_row(group)
      base = (@bare_from&.extreme_row(group) || group.first || Array.new(row_width))
      base + @aggregates.map { |a| a.call(group) }
    end

    # Each row followed by the values of the window calls, over all the rows (6.2).
    def with_window_values(rows)
      return rows if @calculations.empty?

      columns = @calculations.map { |calculation| calculation.values(rows) }
      rows.each_with_index.map { |row, i| row + columns.map { |values| values[i] } }
    end

    # Result rows in final order, duplicates removed before sorting when DISTINCT.
    def project(rows)
      seen = {}
      keyed = rows.filter_map do |row|
        out = @projection.map { |f| f.call(row) }
        if @stmt.distinct
          key = out.each_with_index.map { |v, i| Values.group_key(v, @column_collations[i]) }
          next if seen.key?(key)

          seen[key] = true
        end

        [@order_terms.map { |t| t.key(row, out) }, out]
      end
      keyed = Ordering.sort(keyed, @order_terms) unless @order_terms.empty?
      keyed.map(&:last)
    end
  end
end

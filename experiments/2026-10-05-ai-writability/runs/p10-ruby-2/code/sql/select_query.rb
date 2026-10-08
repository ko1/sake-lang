# frozen_string_literal: true

require_relative 'aggregate_functions'
require_relative 'aggregates'
require_relative 'ast'
require_relative 'compiler'
require_relative 'errors'
require_relative 'from_clause'
require_relative 'limits'
require_relative 'ordering'
require_relative 'query'
require_relative 'scope'
require_relative 'values'

module SQL
  # Plans and runs one SELECT (SPEC 1.7, 3.x, 4.x): compiles every expression first (so name errors come
  # before any row is read), then filters, groups, projects, de-duplicates, sorts and limits.
  #
  # In an aggregate query the rows that HAVING, the result columns and ORDER BY see are "group
  # rows": a joined row of the FROM clause (for bare columns) followed by one slot per aggregate call.
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
      @aggregate_query = !@stmt.group_by.empty? || @columns.any? { |expr, _| !Aggregates.find_calls(expr).empty? }
      plan
    end

    # The result rows, as arrays of values.
    def rows
      rows = @from ? @from.rows : [[]]
      rows = rows.select { |row| Values.truth(@where.call(row)) } if @where
      rows = group_rows(rows) if @aggregate_query
      Limits.window(project(rows), @limit, @offset)
    end

    # Does a name in this query refer to a query around it, so it must run again for each row?
    def correlated? = @correlation.flag

    # Per result column: its name (alias, or a plain column's name; else nil) and its affinity (1.9).
    def result_names
      @columns.map { |expr, al| al || (expr.name if expr.is_a?(ColumnRef) || expr.is_a?(ResolvedColumn)) }
    end

    def affinities = @compiled_columns.map(&:affinity)

    private

    # --- planning -----------------------------------------------------------------------

    def plan
      raise SqlError, 'HAVING clause on a non-aggregate query' if @stmt.having && !@aggregate_query

      @aggregates = @aggregate_query ? build_aggregates : []
      slots = @aggregates.each_index.to_h { |i| [Aggregates.key(@calls[i]), row_width + i] }
      scope = Scope.new(@level, {}, aggregates: @aggregate_query ? slots : nil)
      @compiled_columns = @columns.map { |expr, _| Compiler.new(scope).compile(expr) }
      @projection = @compiled_columns.map(&:fn)
      @where = @stmt.where && Compiler.new(Scope.new(@level, @aliases)).compile(@stmt.where).fn
      @group_terms = @stmt.group_by.each_with_index.map { |t, i| compile_group_term(t, i) }
      @having = @stmt.having && Compiler.new(Scope.new(@level, @aliases, aggregates: slots)).compile(@stmt.having).fn
      order_scope = Scope.new(@level, @aliases, aggregates: @aggregate_query ? slots : nil, misuse: :plain)
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
        [ResolvedColumn.new(source.offset + i, c.name, c.affinity), nil] if keep_hidden || !c.hidden
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

    # The aggregate whose row supplies bare columns: the only call, when it is min/max (3.3).
    def bare_column_aggregate
      return nil unless @aggregates.size == 1 && %w[min max].include?(@aggregates[0].name)

      @aggregates[0]
    end

    def compile_group_term(term, position)
      expr = (k = Limits.ordinal(term)) ? @columns.fetch(Limits.ordinal_index(k, position, 'GROUP', width)).first : term
      Compiler.new(Scope.new(@level, @aliases, misuse: :group_by)).compile(expr).fn
    end

    def compile_order_term(term, position, scope)
      expr = term.expr
      index = fn = nil
      if (k = Limits.ordinal(expr))
        index = Limits.ordinal_index(k, position, 'ORDER', width)
      elsif expr.is_a?(ColumnRef) && expr.table.nil? && (i = @columns.index { |_, al| al&.casecmp?(expr.name) })
        index = i
      else
        fn = Compiler.new(scope).compile(expr).fn
      end
      Ordering::Term.new(term.desc, term.nulls, index, fn)
    end

    def limit_and_offset = Limits.resolve(@stmt.limit, @stmt.offset, @namespace)

    # --- running ------------------------------------------------------------------------

    # The group rows (3.3) that pass HAVING, one per group.
    def group_rows(rows)
      groups =
        if @group_terms.empty?
          [rows]
        else
          rows.group_by { |row| @group_terms.map { |f| Values.group_key(f.call(row)) } }.values
        end
      group_rows = groups.map { |group| group_row(group) }
      @having ? group_rows.select { |r| Values.truth(@having.call(r)) } : group_rows
    end

    def group_row(group)
      base = (@bare_from&.extreme_row(group) || group.first || Array.new(row_width))
      base + @aggregates.map { |a| a.call(group) }
    end

    # Result rows in final order, duplicates removed before sorting when DISTINCT.
    def project(rows)
      seen = {}
      keyed = rows.filter_map do |row|
        out = @projection.map { |f| f.call(row) }
        if @stmt.distinct
          key = out.map { |v| Values.group_key(v) }
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

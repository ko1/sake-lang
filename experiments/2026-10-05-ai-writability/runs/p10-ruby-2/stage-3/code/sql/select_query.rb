# frozen_string_literal: true

require_relative 'aggregate_functions'
require_relative 'aggregates'
require_relative 'ast'
require_relative 'compiler'
require_relative 'errors'
require_relative 'ordering'
require_relative 'values'

module SQL
  # Plans and runs one SELECT (SPEC 1.7, 3.x): compiles every expression first (so name errors come
  # before any row is read), then filters, groups, projects, de-duplicates, sorts and limits.
  #
  # In an aggregate query the rows that HAVING, the result columns and ORDER BY see are "group
  # rows": a row of the table (for bare columns) followed by one slot per aggregate call.
  class SelectQuery
    def initialize(stmt, catalog)
      @stmt = stmt
      @table = stmt.from ? catalog.fetch(stmt.from) : nil
      @columns = expand_result_columns # [[expr, alias]]
      @aliases = @columns.filter_map { |expr, al| [al.downcase, expr] if al }.to_h
      @calls = collect_aggregate_calls
      @aggregate_query = !@stmt.group_by.empty? || @columns.any? { |expr, _| !Aggregates.find_calls(expr).empty? }
      plan
    end

    # The lines to print.
    def run
      rows = @table ? @table.rows : [[]]
      rows = rows.select { |row| Values.truth(@where.call(row)) } if @where
      rows = group_rows(rows) if @aggregate_query
      out_rows = project(rows)
      out_rows = out_rows.drop(@offset)
      out_rows = out_rows.take(@limit) if @limit
      out_rows.map { |r| r.map { |v| Values.display(v) }.join('|') }
    end

    private

    # --- planning -----------------------------------------------------------------------

    def plan
      raise SqlError, 'HAVING clause on a non-aggregate query' if @stmt.having && !@aggregate_query

      @aggregates = @aggregate_query ? build_aggregates : []
      slots = @aggregates.each_index.to_h { |i| [Aggregates.key(@calls[i]), width + i] }
      scope = Scope.new(@table, {}, aggregates: @aggregate_query ? slots : nil)
      @projection = @columns.map { |expr, _| Compiler.new(scope).compile(expr).fn }
      @where = @stmt.where && Compiler.new(Scope.new(@table, @aliases)).compile(@stmt.where).fn
      @group_terms = @stmt.group_by.each_with_index.map { |t, i| compile_group_term(t, i) }
      @having = @stmt.having && Compiler.new(Scope.new(@table, @aliases, aggregates: slots)).compile(@stmt.having).fn
      order_scope = Scope.new(@table, @aliases, aggregates: @aggregate_query ? slots : nil, misuse: :plain)
      @order_terms = @stmt.order_by.each_with_index.map { |t, i| compile_order_term(t, i, order_scope) }
      @limit, @offset = limit_and_offset
      @bare_from = bare_column_aggregate
    end

    def width = @table ? @table.columns.size : 0

    # `*` becomes one column per table column.
    def expand_result_columns
      @stmt.items.flat_map do |item|
        next [[item.expr, item.alias]] unless item.is_a?(Star)
        raise SqlError, 'no tables specified' unless @table

        @table.columns.map { |c| [ColumnRef.new(nil, c.name), nil] }
      end
    end

    # Aggregate calls of the result columns, HAVING and ORDER BY, each distinct one once.
    def collect_aggregate_calls
      parts = [@columns.map(&:first), @stmt.having, @stmt.order_by.map(&:expr)]
      Aggregates.find_calls(parts)
    end

    def build_aggregates
      compiler = Compiler.new(Scope.new(@table))
      @calls.map { |call| Aggregate.new(call, compiler) }
    end

    # The aggregate whose row supplies bare columns: the only call, when it is min/max (3.3).
    def bare_column_aggregate
      return nil unless @aggregates.size == 1 && %w[min max].include?(@aggregates[0].name)

      @aggregates[0]
    end

    def compile_group_term(term, position)
      expr = (k = ordinal(term)) ? @columns.fetch(ordinal_index(k, position, 'GROUP')).first : term
      Compiler.new(Scope.new(@table, @aliases, misuse: :group_by)).compile(expr).fn
    end

    def compile_order_term(term, position, scope)
      expr = term.expr
      index = fn = nil
      if (k = ordinal(expr))
        index = ordinal_index(k, position, 'ORDER')
      elsif expr.is_a?(ColumnRef) && expr.table.nil? && (i = @columns.index { |_, al| al&.casecmp?(expr.name) })
        index = i
      else
        fn = Compiler.new(scope).compile(expr).fn
      end
      Ordering::Term.new(term.desc, term.nulls, index, fn)
    end

    # k for an integer literal or `-` integer literal, else nil.
    def ordinal(expr)
      case expr
      when Literal then expr.value if expr.value.is_a?(Integer)
      when Unary
        v = expr.operand
        -v.value if expr.op == :neg && v.is_a?(Literal) && v.value.is_a?(Integer)
      end
    end

    # Index of the k-th result column for the term at `position` of `clause` (ORDER or GROUP).
    def ordinal_index(k, position, clause)
      unless k.between?(1, @columns.size)
        raise SqlError, "#{ordinal_word(position + 1)} #{clause} BY term out of range - " \
                        "should be between 1 and #{@columns.size}"
      end
      k - 1
    end

    def ordinal_word(n)
      suffix = if (11..13).cover?(n % 100) then 'th'
               else { 1 => 'st', 2 => 'nd', 3 => 'rd' }.fetch(n % 10, 'th')
               end
      "#{n}#{suffix}"
    end

    def limit_and_offset
      limit = @stmt.limit && integer_clause(@stmt.limit)
      limit = nil if limit&.negative?
      offset = @stmt.offset ? [integer_clause(@stmt.offset), 0].max : 0
      [limit, offset]
    end

    def integer_clause(expr)
      v = Compiler.new(Scope::EMPTY).compile(expr).fn.call(nil)
      v = Values.parse_numeric_literal(v) || v if v.is_a?(String)
      v = v.to_i if v.is_a?(Float) && v == v.floor
      raise SqlError, 'datatype mismatch' unless v.is_a?(Integer)

      v
    end

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
      base = (@bare_from&.extreme_row(group) || group.first || Array.new(width))
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

# frozen_string_literal: true

require_relative 'ast'
require_relative 'compiler'
require_relative 'errors'
require_relative 'storage'
require_relative 'values'

module SQL
  # Runs parsed statements against a Catalog. `execute` returns the lines to print.
  class Executor
    def initialize(catalog)
      @catalog = catalog
    end

    def execute(stmt)
      case stmt
      when CreateTable then create_table(stmt)
      when DropTable then drop_table(stmt)
      when Insert then insert(stmt)
      when Select then select(stmt)
      end
    end

    private

    # --- DDL ----------------------------------------------------------------------------

    def create_table(stmt)
      if @catalog.find(stmt.name)
        return [] if stmt.if_not_exists

        raise SqlError, "table #{stmt.name} already exists"
      end
      seen = {}
      stmt.columns.each do |c|
        raise SqlError, "duplicate column name: #{c.name}" if seen[c.name.downcase]

        seen[c.name.downcase] = true
      end
      @catalog.add(Table.new(stmt.name, stmt.columns.map { |c| Column.new(c.name, c.type) }))
      []
    end

    def drop_table(stmt)
      if @catalog.find(stmt.name)
        @catalog.drop(stmt.name)
      elsif !stmt.if_exists
        raise SqlError, "no such table: #{stmt.name}"
      end
      []
    end

    # --- INSERT -------------------------------------------------------------------------

    def insert(stmt)
      table = @catalog.fetch(stmt.table)
      targets = insert_targets(stmt, table)
      width = stmt.rows.first.size
      raise SqlError, 'all VALUES must have the same number of terms' if stmt.rows.any? { |r| r.size != width }

      check_value_count(stmt, table, targets, width)
      compiler = Compiler.new(Scope::EMPTY)
      rows = stmt.rows.map do |exprs|
        values = exprs.map { |e| compiler.compile(e).fn.call(nil) }
        full = Array.new(table.columns.size)
        targets.each_with_index { |col, i| full[col] = values[i] }
        table.coerce_row(full)
      end
      table.append_rows(rows)
      []
    end

    # Column indexes the VALUES positions go to.
    def insert_targets(stmt, table)
      return table.columns.each_index.to_a unless stmt.columns

      stmt.columns.map do |name|
        table.column_index(name) or raise SqlError, "table #{stmt.table} has no column named #{name}"
      end
    end

    def check_value_count(stmt, table, targets, width)
      return if width == targets.size

      if stmt.columns
        raise SqlError, "#{width} values for #{targets.size} columns"
      else
        raise SqlError, "table #{stmt.table} has #{table.columns.size} columns but #{width} values were supplied"
      end
    end

    # --- SELECT -------------------------------------------------------------------------

    def select(stmt)
      table = stmt.from ? @catalog.fetch(stmt.from) : nil
      columns = expand_result_columns(stmt, table) # [[expr, alias]]
      aliases = columns.filter_map { |expr, al| [al.downcase, expr] if al }.to_h
      projection = columns.map { |expr, _| Compiler.new(Scope.new(table)).compile(expr).fn }
      where = stmt.where && Compiler.new(Scope.new(table, aliases)).compile(stmt.where).fn
      terms = stmt.order_by.each_with_index.map { |t, i| compile_order_term(t, i, columns, table, aliases) }
      limit, offset = limit_and_offset(stmt)

      rows = table ? table.rows : [[]]
      rows = rows.select { |row| Values.truth(where.call(row)) } if where
      keyed = rows.each_with_index.map do |row, n|
        out = projection.map { |f| f.call(row) }
        [terms.map { |t| t.key(row, out) }, n, out]
      end
      keyed.sort! { |a, b| compare_keys(terms, a, b) } unless terms.empty?
      out_rows = keyed.map(&:last)
      out_rows = out_rows.drop(offset)
      out_rows = out_rows.take(limit) if limit
      out_rows.map { |r| r.map { |v| Values.display(v) }.join('|') }
    end

    # `*` becomes one column per table column.
    def expand_result_columns(stmt, table)
      stmt.items.flat_map do |item|
        next [[item.expr, item.alias]] unless item.is_a?(Star)
        raise SqlError, 'no tables specified' unless table

        table.columns.map { |c| [ColumnRef.new(nil, c.name), nil] }
      end
    end

    # How one ORDER BY term finds its key: a result column (by position or alias) or an expression.
    OrderKey = Struct.new(:desc, :nulls, :index, :fn) do
      def key(row, out) = index ? out[index] : fn.call(row)
    end

    def compile_order_term(term, position, columns, table, aliases)
      expr = term.expr
      index = nil
      fn = nil
      if (k = ordinal(expr))
        unless k.between?(1, columns.size)
          raise SqlError, "#{ordinal_word(position + 1)} ORDER BY term out of range - " \
                          "should be between 1 and #{columns.size}"
        end
        index = k - 1
      elsif expr.is_a?(ColumnRef) && expr.table.nil? && (i = columns.index { |_, al| al&.casecmp?(expr.name) })
        index = i
      else
        fn = Compiler.new(Scope.new(table, aliases)).compile(expr).fn
      end
      OrderKey.new(term.desc, term.nulls, index, fn)
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

    def ordinal_word(n)
      suffix = if (11..13).cover?(n % 100) then 'th'
               else { 1 => 'st', 2 => 'nd', 3 => 'rd' }.fetch(n % 10, 'th')
               end
      "#{n}#{suffix}"
    end

    def compare_keys(terms, a, b)
      terms.each_with_index do |t, i|
        c = compare_key(t, a[0][i], b[0][i])
        return c unless c.zero?
      end
      a[1] <=> b[1]
    end

    def compare_key(term, x, y)
      if term.nulls && (x.nil? ^ y.nil?)
        return (x.nil? == (term.nulls == :first)) ? -1 : 1
      end

      c = Values.order_compare(x, y)
      term.desc ? -c : c
    end

    def limit_and_offset(stmt)
      limit = stmt.limit && integer_clause(stmt.limit)
      limit = nil if limit && limit.negative?
      offset = stmt.offset ? [integer_clause(stmt.offset), 0].max : 0
      [limit, offset]
    end

    def integer_clause(expr)
      v = Compiler.new(Scope::EMPTY).compile(expr).fn.call(nil)
      v = Values.parse_numeric_literal(v) || v if v.is_a?(String)
      v = v.to_i if v.is_a?(Float) && v == v.floor
      raise SqlError, 'datatype mismatch' unless v.is_a?(Integer)

      v
    end
  end
end

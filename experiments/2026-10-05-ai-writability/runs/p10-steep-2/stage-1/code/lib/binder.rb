module MiniSql
  # Resolves names in an expression against one table (or none) and result-column aliases,
  # raising SqlError for unknown columns and functions before any row is read.
  class Binder
    COMPARISONS = %w[= == != <> < <= > >=].freeze

    # aliases maps a lower-case alias to the bound expression it stands for.
    def initialize(table, aliases)
      @table = table
      @aliases = aliases
    end

    def bind(expr)
      case expr
      when ColumnRef then bind_column(expr)
      when Unary then Unary.new(expr.op, bind(expr.operand))
      when Binary then bind_binary(expr)
      when Not then Not.new(bind(expr.operand))
      when Is then bind_compare(expr.negated ? "IS NOT" : "IS", expr.left, expr.right)
      when Call then bind_call(expr)
      else expr
      end
    end

    private

    def bind_column(ref)
      table = @table
      qualifier = ref.qualifier
      if table && (qualifier.nil? || qualifier.downcase(:ascii) == table.name.downcase(:ascii))
        index = table.column_index(ref.name)
        return BoundColumn.new(index, table.columns.fetch(index).type) if index
      end
      aliased = qualifier ? nil : @aliases[ref.name.downcase(:ascii)]
      aliased || raise(SqlError, "no such column: #{ref.spelling}")
    end

    def bind_binary(expr)
      return bind_compare(expr.op, expr.left, expr.right) if COMPARISONS.include?(expr.op)
      Binary.new(expr.op, bind(expr.left), bind(expr.right))
    end

    def bind_compare(op, left, right)
      bound_left = bind(left)
      bound_right = bind(right)
      Compare.new(op, bound_left, bound_right, affinity(bound_left), affinity(bound_right))
    end

    # The affinity of an expression: its column's type for a column reference, else nil.
    def affinity(expr)
      expr.is_a?(BoundColumn) ? expr.affinity : nil
    end

    def bind_call(call)
      case Functions.check(call.name, call.args.length)
      when :unknown then raise SqlError, "no such function: #{call.name}"
      when :arity then raise SqlError, "wrong number of arguments to function #{call.name}()"
      end
      BoundCall.new(call.name.downcase(:ascii), call.args.map { |arg| bind(arg) })
    end
  end
end

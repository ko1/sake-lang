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
      when Case then bind_case(expr)
      when Between then bind_between(expr)
      when InList then bind_in(expr)
      when Like then Like.new(expr.negated, bind(expr.operand), bind(expr.pattern))
      when Cast then Cast.new(bind(expr.operand), expr.type)
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

    # The affinity of an expression: its column's type for a column reference or the target
    # type of a CAST, else nil.
    def affinity(expr)
      case expr
      when BoundColumn then expr.affinity
      when Cast then expr.type
      end
    end

    # The simple form `CASE x WHEN v` becomes the searched form `CASE WHEN x = v`.
    def bind_case(expr)
      operand = expr.operand
      whens = expr.whens.map do |clause|
        condition = operand ? bind_compare("=", operand, clause.condition) : bind(clause.condition)
        WhenClause.new(condition, bind(clause.result))
      end
      else_expr = expr.else_expr
      Case.new(nil, whens, else_expr && bind(else_expr))
    end

    # `x BETWEEN a AND b` is `x >= a AND x <= b` (x has no side effects, so evaluating it twice is safe).
    def bind_between(expr)
      range = Binary.new("AND", bind_compare(">=", expr.operand, expr.low), bind_compare("<=", expr.operand, expr.high))
      expr.negated ? Not.new(range) : range
    end

    # `x IN (a, b)` is `x = a OR x = b`, converting each item to x's affinity only (no affinity
    # of its own); an empty list is false.
    def bind_in(expr)
      operand = bind(expr.operand)
      operand_affinity = affinity(operand)
      found = Literal.new(0) # @type var found: Expr
      expr.items.each_with_index do |item, i|
        test = Compare.new("=", operand, bind(item), operand_affinity, nil)
        found = i.zero? ? test : Binary.new("OR", found, test)
      end
      expr.negated ? Not.new(found) : found
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

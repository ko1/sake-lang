module MiniSql
  # Resolves names in an expression against one table (or none) and result-column aliases,
  # raising SqlError for unknown columns and functions before any row is read.
  class Binder
    COMPARISONS = %w[= == != <> < <= > >=].freeze

    # aliases maps a lower-case alias to the bound expression it stands for. Aggregate calls are
    # collected in scope; with no scope they are refused, and refusal (:where, :group_by or
    # :order_by) names the clause, which decides the error message.
    def initialize(table, aliases, scope: nil, refusal: :where)
      @table = table
      @aliases = aliases
      @scope = scope
      @refusal = refusal
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
      raise SqlError, "no such column: #{ref.spelling}" unless aliased
      refuse_aggregate_alias(aliased) unless @scope
      aliased
    end

    # An alias standing for an aggregate cannot be used where aggregates are refused.
    def refuse_aggregate_alias(aliased)
      name = aliased.aggregate_name
      return unless name
      raise SqlError, "aggregate functions are not allowed in the GROUP BY clause" if @refusal == :group_by
      raise SqlError, "misuse of aggregate: #{name}()"
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
      return bind_aggregate(call) if Aggregates.aggregate?(call.name, call.args.length)
      case Functions.check(call.name, call.args.length)
      when :unknown then raise SqlError, "no such function: #{call.name}"
      when :arity then raise SqlError, "wrong number of arguments to function #{call.name}()"
      end
      raise SqlError, "wrong number of arguments to function #{call.name}()" if call.star
      if call.distinct || !call.order_by.empty?
        raise SqlError, "DISTINCT and ORDER BY are only allowed in aggregate functions: #{call.name}()"
      end
      BoundCall.new(call.name.downcase(:ascii), call.args.map { |arg| bind(arg) })
    end

    def bind_aggregate(call)
      lower = call.name.downcase(:ascii)
      unless Aggregates.arity_ok?(lower, call.args.length) && (!call.star || lower == "count")
        raise SqlError, "wrong number of arguments to function #{call.name}()"
      end
      raise SqlError, "DISTINCT aggregates must have exactly one argument" if call.distinct && call.args.length != 1
      scope = @scope || refuse_aggregate(call.name)
      # Aggregate calls do not nest: the arguments are bound where aggregates are refused.
      inner = Binder.new(@table, @aliases)
      args = call.args.map { |arg| inner.bind(arg) }
      order = call.order_by.map { |term| SortKey.new(nil, inner.bind(term.expr), term.descending, term.nulls) }
      spec = AggregateSpec.new(lower, args, call.args.empty?, call.distinct, order)
      scope.ref_for(call.signature, call.name, spec)
    end

    def refuse_aggregate(name)
      case @refusal
      when :group_by then raise SqlError, "aggregate functions are not allowed in the GROUP BY clause"
      when :order_by then raise SqlError, "misuse of aggregate: #{name}()"
      else raise SqlError, "misuse of aggregate function #{name}()"
      end
    end
  end
end

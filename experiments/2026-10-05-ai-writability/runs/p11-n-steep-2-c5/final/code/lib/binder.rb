module MiniSql
  # Resolves names in an expression against the sources of a query, result-column aliases and the enclosing
  # queries, raising SqlError for unknown columns and functions before any row is read.
  class Binder
    COMPARISONS = %w[= == != <> < <= > >=].freeze

    # aliases maps a lower-case alias to the bound expression it stands for. Aggregate calls are
    # collected in `aggregates`; with none they are refused, and refusal (:where, :group_by or
    # :order_by) names the clause, which decides the error message. Window calls are collected in `windows`
    # and refused without it.
    def initialize(sources, aliases, environment, aggregates: nil, windows: nil, refusal: :where)
      @sources = sources
      @aliases = aliases
      @environment = environment
      @aggregates = aggregates
      @windows = windows
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
      when Like then bind_like(expr)
      when Glob then Glob.new(expr.negated, bind(expr.operand), bind(expr.pattern))
      when Cast then Cast.new(bind(expr.operand), expr.type)
      when ScalarSelect then bind_scalar(expr, false)
      when ExistsSelect then BoundExists.new(plan_subquery(expr.select), @environment.frame)
      when InSelect then bind_in_select(expr)
      else expr
      end
    end

    private

    def bind_like(expr)
      escape = expr.escape
      Like.new(expr.negated, bind(expr.operand), bind(expr.pattern), escape ? bind(escape) : nil)
    end

    # The column in this query's sources, else its aliases, else the same in each enclosing query.
    def bind_column(ref)
      local = resolve_in(@sources, @aliases, ref)
      if local
        refuse_aggregate_alias(local) unless @aggregates
        refuse_window_alias(local, ref.name) unless @windows
        return local
      end
      outer = @environment.outer # @type var outer: Outer?
      while outer
        found = resolve_in(outer.sources, outer.aliases, ref)
        return OuterRef.new(outer.frame, found) if found
        outer = outer.parent
      end
      raise SqlError, "no such column: #{ref.spelling}"
    end

    # nil when the query does not know the name; a qualifier that names one of its sources must find the column there.
    def resolve_in(sources, aliases, ref)
      qualifier = ref.qualifier
      return nil unless qualifier.nil? || sources.named?(qualifier)
      column = sources.find(qualifier, ref.name)
      return column if column
      raise SqlError, "no such column: #{ref.spelling}" if qualifier
      aliases[ref.name.downcase(:ascii)]
    end

    # An alias standing for an aggregate cannot be used where aggregates are refused.
    def refuse_aggregate_alias(aliased)
      name = aliased.aggregate_name
      return unless name
      raise SqlError, "aggregate functions are not allowed in the GROUP BY clause" if @refusal == :group_by
      raise SqlError, "misuse of aggregate: #{name}()"
    end

    # An alias standing for a window call cannot be used where window calls are refused.
    def refuse_window_alias(aliased, alias_name)
      raise SqlError, "misuse of aliased window function #{alias_name}" if aliased.window_name
    end

    def plan_subquery(select)
      outer = Outer.new(@sources, @aliases, @environment.frame, @environment.outer)
      Planner.new(@environment.database, select, outer, @environment.ctes).plan
    end

    # `( select )` as a value; a comparison operand (misuse) reports a wider select as a row value.
    def bind_scalar(expr, misuse)
      plan = plan_subquery(expr.select)
      count = plan.columns.length
      raise SqlError, (misuse ? "row value misused" : "sub-select returns #{count} columns - expected 1") unless count == 1
      BoundScalar.new(plan, @environment.frame)
    end

    def bind_in_select(expr)
      operand = bind(expr.operand)
      plan = plan_subquery(expr.select)
      count = plan.columns.length
      raise SqlError, "sub-select returns #{count} columns - expected 1" unless count == 1
      BoundIn.new(operand, expr.negated, plan, @environment.frame)
    end

    def bind_binary(expr)
      return bind_compare(expr.op, expr.left, expr.right) if COMPARISONS.include?(expr.op)
      Binary.new(expr.op, bind(expr.left), bind(expr.right))
    end

    def bind_compare(op, left, right)
      null_test = (op == "IS" || op == "IS NOT") && right.is_a?(Literal) && right.value.nil?
      bound_left = null_test ? bind(left) : bind_operand(left)
      bound_right = null_test ? bind(right) : bind_operand(right)
      Compare.new(op, bound_left, bound_right, bound_left.affinity, bound_right.affinity)
    end

    def bind_operand(expr)
      expr.is_a?(ScalarSelect) ? bind_scalar(expr, true) : bind(expr)
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
      operand_affinity = operand.affinity
      found = Literal.new(0) # @type var found: Expr
      expr.items.each_with_index do |item, i|
        test = Compare.new("=", operand, bind(item), operand_affinity, nil)
        found = i.zero? ? test : Binary.new("OR", found, test)
      end
      expr.negated ? Not.new(found) : found
    end

    def bind_call(call)
      over = call.over
      return bind_window_call(call, over) if over
      lower = call.name.downcase(:ascii)
      raise SqlError, "misuse of window function #{call.name}()" if WindowFunctions.known?(lower)
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
      aggregates = @aggregates || refuse_aggregate(call.name)
      # Aggregate calls do not nest: the arguments are bound where aggregates are refused.
      inner = Binder.new(@sources, @aliases, @environment)
      args = call.args.map { |arg| inner.bind(arg) }
      order = call.order_by.map { |term| SortKey.new(nil, inner.bind(term.expr), term.descending, term.nulls) }
      spec = AggregateSpec.new(lower, args, call.args.empty?, call.distinct, order)
      aggregates.ref_for(call.signature, call.name, spec)
    end

    # `name(args) OVER ...`: an aggregate over the frame or a window function (SPEC 6.3).
    def bind_window_call(call, over)
      windows = @windows
      raise SqlError, "misuse of window function #{call.name}()" unless windows
      lower = call.name.downcase(:ascii)
      aggregate = Aggregates.aggregate?(call.name, call.args.length)
      raise SqlError, "#{call.name}() may not be used as a window function" unless aggregate || WindowFunctions.known?(lower)
      arity_ok = aggregate ? Aggregates.arity_ok?(lower, call.args.length) && (!call.star || lower == "count") :
                             WindowFunctions.arity_ok?(lower, call.args.length) && !call.star
      raise SqlError, "wrong number of arguments to function #{call.name}()" unless arity_ok
      if call.distinct || !call.order_by.empty?
        raise SqlError, "DISTINCT and ORDER BY are not supported for window functions: #{call.name}()"
      end
      # Window calls do not nest: the arguments and the window's terms are bound where windows are refused.
      inner = Binder.new(@sources, @aliases, @environment, aggregates: @aggregates, refusal: @refusal)
      args = call.args.map { |arg| inner.bind(arg) }
      definition = bind_window_definition(windows.resolve(over))
      spec = aggregate ? AggregateSpec.new(lower, args, call.args.empty?, false, []) : nil
      windows.add(WindowCall.new(lower, args, spec, definition), call.name)
    end

    # The terms of a window are plain expressions on the sources: result column aliases are not visible.
    def bind_window_definition(spec)
      inner = Binder.new(@sources, {}, @environment, aggregates: @aggregates, refusal: @refusal)
      partition_by = spec.partition_by.map { |term| inner.bind(term) }
      order = spec.order_by.map { |term| SortKey.new(nil, inner.bind(term.expr), term.descending, term.nulls) }
      WindowDef.build(partition_by, order, spec.frame)
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

require_relative "errors"
require_relative "ast"
require_relative "scope"
require_relative "expressions"
require_relative "functions"
require_relative "aggregates"
require_relative "windows"

# Resolves the names in a syntax-tree expression and returns the bound expression (Expressions).
# All name, function and subquery-shape errors are raised here, before any row is read.
#
# What a name and an aggregate call mean depends on the clause (spec 1.7, 3.3, 4.2), so a Binder is
# made for one clause:
# - scope: the sources whose columns are in scope (Scope), empty for no row;
# - catalog: where the named sources (tables, views, ctes) of subqueries are found (Catalog);
# - aliases: name (downcased) => the syntax tree of that result column, consulted when no column
#   matches (empty where aliases are not visible);
# - aggregates: the query's Aggregates::Collector where aggregate calls are allowed, else nil;
# - misuse: the error message for an aggregate call where it is not allowed, given the call's name;
#   alias_misuse: the same for one reached through an alias;
# - outer: the Binder of the enclosing query's clause that contains this query, or nil;
# - windows: the query's Windows::Collector where window calls are allowed (6.2), else nil;
#   window_alias: the alias through which this expression was reached, for the misuse message.
class Binder
  MISUSE_FUNCTION = ->(name) { "misuse of aggregate function #{name}()" }
  MISUSE_AGGREGATE = ->(name) { "misuse of aggregate: #{name}()" }
  MISUSE_GROUP_BY = ->(_name) { "aggregate functions are not allowed in the GROUP BY clause" }
  COMPARISONS = %w[= == != <> < <= > >= IS] + ["IS NOT"]

  # Binds an expression with no row in scope (INSERT values, LIMIT).
  def self.bind(expr, catalog)
    new(Scope.new, catalog).bind(expr)
  end

  def initialize(scope, catalog, aliases: {}, aggregates: nil, misuse: MISUSE_FUNCTION,
                 alias_misuse: misuse, outer: nil, windows: nil, window_alias: nil)
    @windows = windows
    @window_alias = window_alias
    @scope = scope
    @catalog = catalog
    @aliases = aliases
    @aggregates = aggregates
    @misuse = misuse
    @alias_misuse = alias_misuse
    @outer = outer
  end

  def bind(expr)
    case expr
    when AST::Literal then Expressions::Constant.new(expr.value)
    when AST::Name then resolve_name(expr.name)
    when AST::QualifiedName then resolve_qualified(expr)
    when AST::SourceColumn then column_ref(expr.column)
    when AST::Paren then bind(expr.expr)
    when AST::Unary then bind_unary(expr)
    when AST::Binary then bind_binary(expr)
    when AST::Call then bind_call(expr)
    when AST::Case
      whens = expr.whens.map { |condition, result| [bind(condition), bind(result)] }
      Expressions::Case.new(expr.base && bind_operand(expr.base), whens, expr.else_expr && bind(expr.else_expr))
    when AST::Between
      Expressions::Between.new(bind_operand(expr.expr), bind_operand(expr.low), bind_operand(expr.high), expr.negated)
    when AST::In then Expressions::In.new(bind(expr.expr), expr.list.map { |e| bind(e) }, expr.negated)
    when AST::InSelect
      Expressions::InSubquery.new(bind(expr.expr), single_column_query(expr.select), expr.negated)
    when AST::Like then Expressions::Like.new(bind(expr.expr), bind(expr.pattern), expr.negated)
    when AST::Cast then Expressions::Cast.new(bind(expr.expr), expr.type)
    when AST::Collate then Expressions::Collate.new(bind(expr.expr), Collation.lookup(expr.collation))
    when AST::Subquery then Expressions::ScalarSubquery.new(single_column_query(expr.select))
    when AST::Exists then Expressions::Exists.new(subquery(expr.select))
    else raise ArgumentError, "unknown expression #{expr.inspect}"
    end
  end

  # [expr, descending, nulls_first, collation] for an ordering term (an AST::OrderingTerm) whose
  # expression is bound as expr: it sorts under expr's collation (7.4).
  def self.ordering(expr, term)
    [expr, term.descending, term.nulls_first, Collation.name_of(expr)]
  end

  # The number of queries enclosing this clause's query: how many Frames out its outer names are.
  def depth = @outer ? @outer.depth + 1 : 0

  protected

  # An unqualified name (4.2): the one source column of that name, else a result column's alias
  # (bound as its expression, where an aggregate call is reported by alias_misuse), else the name in
  # the enclosing query.
  def resolve_name(name)
    columns = @scope.lookup(name)
    raise SqlError, "ambiguous column name: #{name}" if columns.length > 1
    return column_ref(columns[0]) if columns.length == 1
    if (expr = @aliases[name.downcase])
      return Binder.new(@scope, @catalog, aggregates: @aggregates, misuse: @alias_misuse, outer: @outer,
                        windows: @windows, window_alias: @window_alias || name).bind(expr)
    end
    return Expressions::Outer.new(@outer.resolve_name(name)) if @outer
    raise SqlError, "no such column: #{name}"
  end

  # source.name: that column of the innermost source of that name (4.2). SQLite would go on to an
  # enclosing query's source of that name when this one lacks the column; see spec-issues/ref-4.md.
  def resolve_qualified(expr)
    source = @scope.source(expr.source)
    return Expressions::Outer.new(@outer.resolve_qualified(expr)) if source.nil? && @outer
    column = source && Scope.column_in(source, expr.name.downcase)
    raise SqlError, "no such column: #{expr.source}.#{expr.name}" unless column
    column_ref(column)
  end

  private

  def column_ref(column) = Expressions::ColumnRef.new(column.index, column.affinity, column.collation)

  # A subquery of this clause: its outer names are looked up here.
  def subquery(select)
    Query.build(select, @catalog, self)
  end

  def single_column_query(select, error: nil)
    query = subquery(select)
    n = query.affinities.length
    raise SqlError, (error || "sub-select returns #{n} columns - expected 1") unless n == 1
    query
  end

  # An operand of a comparison, of BETWEEN or of CASE x, where a subquery of several columns is a
  # row value (4.3).
  def bind_operand(expr)
    inner = expr
    inner = inner.expr while inner.is_a?(AST::Paren)
    return bind(expr) unless inner.is_a?(AST::Subquery)
    Expressions::ScalarSubquery.new(single_column_query(inner.select, error: "row value misused"))
  end

  def bind_call(call)
    return bind_window_call(call) if call.over
    raise SqlError, window_misuse(call) if Windows.window_only?(call.name)
    definition = Aggregates.lookup(call)
    return bind_scalar_call(call) unless definition
    raise SqlError, @misuse.(call.name) unless @aggregates
    # The arguments see the same names, but an aggregate call inside them is misused.
    inner = Binder.new(@scope, @catalog, aliases: @aliases, outer: @outer)
    order_by = call.order_by.map { |term| Binder.ordering(inner.bind(term.expr), term) }
    bound = Aggregates::Call.new(definition, call.args.map { |arg| inner.bind(arg) }, call.distinct, order_by)
    Expressions::AggregateRef.new(@aggregates.add(AST.normalize(call), bound))
  end

  def window_misuse(call)
    @window_alias ? "misuse of aliased window function #{@window_alias}" : "misuse of window function #{call.name}()"
  end

  # name(...) OVER window (6): allowed only where this clause has the query's windows. Its arguments
  # see the same names, aggregate calls included; its window's terms do not see aliases (6.1); a window
  # call inside either is misused.
  def bind_window_call(call)
    raise SqlError, window_misuse(call) unless @windows
    kind, definition = Windows.function(call)
    spec = @windows.resolve(call.over)
    inner = Binder.new(@scope, @catalog, aliases: @aliases, aggregates: @aggregates, misuse: @misuse, outer: @outer)
    args = call.args.map { |arg| inner.bind(arg) }
    terms = Binder.new(@scope, @catalog, aggregates: @aggregates, misuse: @misuse, outer: @outer)
    partition_by = spec.partition_by.map { |expr| terms.bind(expr) }
    order_by = spec.order_by.map { |term| Binder.ordering(terms.bind(term.expr), term) }
    frame = Windows.frame(spec.frame, order_by.length) { |offset| Binder.bind(offset, @catalog).evaluate(Expressions::EMPTY_FRAME) }
    window = Windows::Window.new(partition_by, order_by, frame)
    Expressions::WindowRef.new(@windows.add(Windows::Call.new(kind, definition, args, window)))
  end

  # DISTINCT in a scalar call has no effect, as in SQLite (the spec does not say).
  def bind_scalar_call(call)
    raise SqlError, "wrong number of arguments to function #{call.name}()" if call.star && Functions::TABLE.key?(call.name.downcase)
    function = Functions.lookup(call.name, call.args.length)
    raise SqlError, "ORDER BY may not be used with non-aggregate #{call.name}()" unless call.order_by.empty?
    Expressions::FunctionCall.new(function, call.args.map { |arg| bind(arg) })
  end

  def bind_unary(expr)
    operand = bind(expr.operand)
    case expr.op
    when "-" then Expressions::Negate.new(operand)
    when "+" then Expressions::Identity.new(operand)
    when "NOT" then Expressions::Not.new(operand)
    end
  end

  def bind_binary(expr)
    if COMPARISONS.include?(expr.op)
      # `x IS [NOT] NULL` with the literal NULL is no comparison of a row value (4.3).
      null_test = expr.op.start_with?("IS") && expr.right.is_a?(AST::Literal) && expr.right.value.nil?
      left = null_test ? bind(expr.left) : bind_operand(expr.left)
      return Expressions::Comparison.new(expr.op, left, bind_operand(expr.right))
    end
    left = bind(expr.left)
    right = bind(expr.right)
    case expr.op
    when "AND" then Expressions::And.new(left, right)
    when "OR" then Expressions::Or.new(left, right)
    when "||" then Expressions::Concat.new(left, right)
    when "+", "-", "*", "/", "%" then Expressions::Arithmetic.new(expr.op, left, right)
    end
  end
end

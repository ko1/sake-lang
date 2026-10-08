# frozen_string_literal: true

require_relative "aggregates"
require_relative "ast"
require_relative "call_slots"
require_relative "error"
require_relative "functions"
require_relative "scope"
require_relative "window_functions"

module Sql
  # Checks the names in an expression (columns, aliases, functions) and rewrites column
  # references to ResolvedColumn and subqueries to plans (built by Planner, which query.rb requires:
  # plans nest, so this file reaches it only when it runs). aliases maps a folded result-column alias to that column's
  # already resolved expression, which a reference to the alias stands for.
  #
  # mode says where the expression is and so what an aggregate or window call in it means: :allow
  # (result columns and ORDER BY of an aggregate query; calls are added to slots), :having (HAVING,
  # and what a window call contains: aggregates but no window calls), :order (ORDER BY of a plain
  # query: window calls but no aggregates), or an error for both in :where (also UPDATE, DELETE,
  # VALUES, LIMIT) and :group_by.
  class Resolver
    def initialize(scope, aliases, mode = :where, slots = nil)
      @scope = scope
      @aliases = aliases
      @mode = mode
      @slots = slots
    end

    def resolve(expr)
      case expr
      when Ast::ColumnRef then resolve_column(expr)
      when Ast::Unary then Ast::Unary.new(expr.op, resolve(expr.operand))
      when Ast::Binary then resolve_binary(expr)
      when Ast::Is then resolve_is(expr)
      when Ast::FunctionCall then resolve_call(expr)
      when Ast::CaseExpr then resolve_case(expr)
      when Ast::Between then Ast::Between.new(operand(expr.value), operand(expr.low), operand(expr.high), expr.negated)
      when Ast::InList then Ast::InList.new(resolve(expr.value), expr.candidates.map { |e| resolve(e) }, expr.negated)
      when Ast::Like then resolve_like(expr)
      when Ast::Glob then Ast::Glob.new(resolve(expr.value), resolve(expr.pattern), expr.negated)
      when Ast::Cast then Ast::Cast.new(resolve(expr.operand), expr.type)
      when Ast::ScalarSubquery then resolve_scalar(expr, false)
      when Ast::ExistsSubquery then Ast::ExistsPlan.new(plan_of(expr.select))
      when Ast::InSubquery then resolve_in_subquery(expr)
      else expr
      end
    end

    private

    def resolve_like(expr)
      escape = expr.escape
      Ast::Like.new(resolve(expr.value), resolve(expr.pattern), expr.negated, escape ? resolve(escape) : nil)
    end

    COMPARISONS = %w[= != < <= > >=].freeze

    # The frame of a window without one: from the partition's start to the current row's last peer.
    DEFAULT_FRAME = Ast::Frame.new(:range, Ast::FrameBound.new(:unbounded_preceding, nil),
                                   Ast::FrameBound.new(:current, nil))

    # A column of this query's sources, else a result column alias, else a column of an
    # enclosing query.
    def resolve_column(ref)
      name = ref.name
      qualifier = ref.qualifier
      if qualifier
        found = @scope.find_qualified(qualifier, name) || raise(Error, "no such column: #{qualifier}.#{name}")
        return Ast::ResolvedColumn.new(found.index, found.type)
      end
      own = @scope.find_own(name)
      return Ast::ResolvedColumn.new(own.index, own.type) if own

      aliased = @aliases[Names.fold(name)]
      if aliased
        window = aliased.first_window
        raise Error, "misuse of aliased window function #{name}" if window && !windows_allowed?

        call = aliased.first_aggregate
        reject_aggregate(call.name, true) if call && !aggregates_allowed?
        return aliased
      end
      outer = @scope.find_outer(name) || raise(Error, "no such column: #{name}")
      Ast::ResolvedColumn.new(outer.index, outer.type)
    end

    def resolve_binary(expr)
      if COMPARISONS.include?(expr.op)
        Ast::Binary.new(expr.op, operand(expr.left), operand(expr.right))
      else
        Ast::Binary.new(expr.op, resolve(expr.left), resolve(expr.right))
      end
    end

    # IS NULL and IS NOT NULL do not compare, so a subquery beside the NULL is not an operand.
    def resolve_is(expr)
      right = expr.right
      if right.is_a?(Ast::Literal) && right.value.nil?
        Ast::Is.new(resolve(expr.left), right, expr.negated)
      else
        Ast::Is.new(operand(expr.left), operand(right), expr.negated)
      end
    end

    # An operand of a comparison: a subquery with several columns is a row value there.
    def operand(expr)
      expr.is_a?(Ast::ScalarSubquery) ? resolve_scalar(expr, true) : resolve(expr)
    end

    def plan_of(select)
      Planner.build(select, @scope.namespace, @scope)
    end

    def resolve_scalar(expr, compared)
      plan = plan_of(expr.select)
      count = plan.column_count
      raise Error, "row value misused" if compared && count > 1
      raise Error, "sub-select returns #{count} columns - expected 1" if count != 1

      Ast::ScalarPlan.new(plan)
    end

    def resolve_in_subquery(expr)
      value = resolve(expr.value)
      plan = plan_of(expr.select)
      count = plan.column_count
      raise Error, "sub-select returns #{count} columns - expected 1" if count != 1

      Ast::InPlan.new(value, plan, expr.negated)
    end

    def aggregates_allowed?
      @mode == :allow || @mode == :having
    end

    def windows_allowed?
      @mode == :allow || @mode == :order
    end

    # Raises the error for an aggregate call (or, by_alias, a reference to a result column
    # holding one) in a place that does not allow it.
    def reject_aggregate(name, by_alias)
      raise Error, "aggregate functions are not allowed in the GROUP BY clause" if @mode == :group_by

      raise Error, by_alias || @mode == :order ? "misuse of aggregate: #{name}()" : "misuse of aggregate function #{name}()"
    end

    def resolve_case(expr)
      subject = expr.subject
      resolved_subject = subject ? operand(subject) : nil
      whens = expr.whens.map { |w| Ast::WhenClause.new(resolve(w.condition), resolve(w.result)) }
      else_result = expr.else_result
      Ast::CaseExpr.new(resolved_subject, whens, else_result ? resolve(else_result) : nil)
    end

    def resolve_call(call)
      function = Names.fold(call.name)
      over = call.over
      return resolve_window_call(call, function, over) if over
      raise Error, "misuse of window function #{call.name}()" if WindowFunctions.window_only?(function)
      return resolve_aggregate(call, function) if Aggregates.aggregate?(function, call.args.length)

      spec = Functions.lookup(call.name)
      raise Error, "no such function: #{call.name}" unless spec
      raise Error, "wrong number of arguments to function #{call.name}()" unless !call.star && spec.accepts?(call.args.length)
      raise Error, "ORDER BY may not be used with non-aggregate #{call.name}()" unless call.order_by.empty?
      raise Error, "DISTINCT is not supported for non-aggregate function #{call.name}()" if call.distinct

      Ast::FunctionCall.new(call.name, call.args.map { |arg| resolve(arg) })
    end

    def resolve_aggregate(call, function)
      argc = call.args.length
      raise Error, "wrong number of arguments to function #{call.name}()" unless Aggregates.accepts?(function, argc, call.star)
      raise Error, "DISTINCT aggregates must have exactly one argument" if call.distinct && argc != 1

      slots = @slots
      return reject_aggregate(call.name, false) unless slots && aggregates_allowed?

      inner = argument_resolver
      args = call.args.map { |arg| inner.resolve(arg) }
      order_by = call.order_by.map { |term| Ast::OrderTerm.new(inner.resolve(term.expr), term.descending, term.nulls_first) }
      slots.add_aggregate(call.name, function, args, call.distinct, call.star, order_by)
    end

    # name(args) OVER window: an aggregate over the window's frame, or a window-only function.
    def resolve_window_call(call, function, over)
      slots = @slots
      raise Error, "misuse of window function #{call.name}()" unless slots && windows_allowed?

      argc = call.args.length
      is_aggregate = Aggregates.aggregate?(function, argc)
      if is_aggregate
        raise Error, "wrong number of arguments to function #{call.name}()" unless Aggregates.accepts?(function, argc, call.star)
      elsif WindowFunctions.window_only?(function)
        raise Error, "wrong number of arguments to function #{call.name}()" unless !call.star && WindowFunctions.accepts?(function, argc)
      else
        raise Error, "#{call.name}() may not be used as a window function"
      end
      raise Error, "DISTINCT is not supported for window functions" if call.distinct
      raise Error, "ORDER BY may not be used with window function #{call.name}()" unless call.order_by.empty?

      inner = Resolver.new(@scope, @aliases, :having, slots)
      args = call.args.map { |arg| inner.resolve(arg) }
      spec = resolve_window(slots.window_defs.bind(over))
      aggregate = is_aggregate ? Ast::Aggregate.new(call.name, function, args, false, call.star, [], -1) : nil
      slots.add_window(call.name, function, args, spec, spec.frame || DEFAULT_FRAME, aggregate)
    end

    # The window with PARTITION BY and ORDER BY resolved (result column aliases are not visible there).
    def resolve_window(spec)
      inner = Resolver.new(@scope, {}, :having, @slots)
      order_by = spec.order_by.map { |term| Ast::OrderTerm.new(inner.resolve(term.expr), term.descending, term.nulls_first) }
      Ast::WindowSpec.new(nil, spec.partition_by.map { |expr| inner.resolve(expr) }, order_by, spec.frame)
    end

    # Arguments of an aggregate are evaluated per row, so no aggregate may appear in them.
    def argument_resolver
      Resolver.new(@scope, @aliases, :where)
    end
  end
end

# frozen_string_literal: true

require_relative "aggregates"
require_relative "ast"
require_relative "errors"
require_relative "functions"
require_relative "identifier"
require_relative "ordering"
require_relative "scope"
require_relative "windows"

module Sql
  # Checks every name and function in an expression, before any row is read, and returns the
  # expression with columns resolved (ColumnRef) and functions looked up.
  module Binder
    module_function

    def bind(node, scope)
      case node
      when Literal, ColumnRef, AggRef, WindowRef then node
      when Column then scope.resolve(node)
      when Unary then Unary.new(node.op, bind(node.operand, scope))
      when Binary then bind_binary(node, scope)
      when Call then bind_call(node, scope)
      when Case
        Case.new(node.operand && bind_operand(node.operand, scope),
                 node.whens.map { |c, r| [bind(c, scope), bind(r, scope)] },
                 node.else_expr && bind(node.else_expr, scope))
      when Between
        Between.new(bind_operand(node.expr, scope), bind_operand(node.low, scope),
                    bind_operand(node.high, scope), node.negated)
      when In then In.new(bind(node.expr, scope), node.list.map { |e| bind(e, scope) }, node.negated)
      when Like then Like.new(bind(node.expr, scope), bind(node.pattern, scope), node.negated)
      when Cast then Cast.new(bind(node.expr, scope), node.type)
      when Subquery then bind_subquery(node, scope)
      when InSubquery
        InSubquery.new(expr: bind(node.expr, scope), query: single_column_query(node.query, scope),
                       negated: node.negated, outer_width: scope.row_width)
      when Exists then Exists.new(query: scope.plan_subquery(node.query), outer_width: scope.row_width)
      else
        raise "cannot bind #{node.inspect}"
      end
    end

    COMPARISON_OPS = %i[eq ne lt le gt ge is isnot].freeze

    def bind_binary(node, scope)
      # `x IS NULL` with the literal NULL is not a comparison of x as far as a subquery x is concerned
      comparison = COMPARISON_OPS.include?(node.op) && node.right != Literal.new(nil)
      bind_side = comparison ? method(:bind_operand) : method(:bind)
      Binary.new(node.op, bind_side.call(node.left, scope), bind_side.call(node.right, scope))
    end

    # A direct operand of a comparison, BETWEEN or CASE x: a scalar subquery here must not be a row value.
    def bind_operand(node, scope)
      node.is_a?(Subquery) ? bind_subquery(node, scope, "row value misused") : bind(node, scope)
    end

    def bind_subquery(node, scope, too_wide = nil)
      Subquery.new(query: single_column_query(node.query, scope, too_wide), outer_width: scope.row_width)
    end

    def single_column_query(select, scope, too_wide = nil)
      query = scope.plan_subquery(select)
      n = query.result_columns.length
      raise SqlError, too_wide || "sub-select returns #{n} columns - expected 1" unless n == 1
      query
    end

    def bind_call(call, scope)
      return bind_window(call, scope) if call.over
      raise SqlError, "misuse of window function #{call.name}()" if Windows.window_only?(call.name)
      return bind_aggregate(call, scope) if Aggregates.aggregate_call?(call)
      raise SyntaxError if call.star || call.distinct || !call.order_by.empty?
      fn = Functions.lookup(call.name, call.args.length)
      Call.new(name: call.name, args: call.args.map { |a| bind(a, scope) }, fn: fn)
    end

    # f(...) OVER ...: the window spec is looked up (a name, or a base), its parts bound, the call recorded.
    def bind_window(call, scope)
      scope.windows.check_call(call.name)
      spec = scope.windows.resolve(call.over)
      inner = scope.for_window_arguments
      args = call.args.map { |a| bind(a, inner) }
      partition_by = spec.partition_by.map { |e| bind(e, inner) }
      order_by = spec.order_by.map { |t| Ordering::SortKey.new(nil, bind(t.expr, inner), t.desc, t.nulls) }
      scope.windows.add(Windows.bound_call(call, args, spec, partition_by, order_by), call.name)
    end

    def bind_aggregate(call, scope)
      inner = scope.for_aggregate_arguments
      args = call.args.map { |a| bind(a, inner) }
      order_by = call.order_by.map { |t| Ordering::SortKey.new(nil, bind(t.expr, inner), t.desc, t.nulls) }
      scope.aggregates.add(Aggregates.spec_for(call, args, order_by), call.name)
    end
  end
end

# frozen_string_literal: true

require_relative "aggregates"
require_relative "ast"
require_relative "errors"
require_relative "functions"
require_relative "identifier"

module Sql
  # What names mean at one place in a statement: the columns of the table (if any), in WHERE and
  # ORDER BY the aliases of the result columns (already bound expressions), and what an aggregate
  # call does here (collected, or an error).
  class Scope
    NO_AGGREGATES = Aggregates::Forbidden.new("misuse of aggregate function %s()", "misuse of aggregate: %s()")

    attr_reader :aggregates

    def initialize(table: nil, aliases: {}, aggregates: NO_AGGREGATES)
      @table = table
      @aliases = aliases
      @aggregates = aggregates
    end

    # The scope of an aggregate call's arguments: the table's columns only, no nested aggregates.
    def for_aggregate_arguments
      Scope.new(table: @table)
    end

    # The bound expression a Column node stands for, or a "no such column" error.
    def resolve(column)
      table_ok = column.table.nil? || (@table && Sql.fold(column.table) == Sql.fold(@table.name))
      if @table && table_ok && (index = @table.column_index(column.name))
        return ColumnRef.new(index, @table.columns[index].type)
      end
      if column.table.nil? && (expr = @aliases[Sql.fold(column.name)])
        @aggregates.check_alias(expr)
        return expr
      end
      written = column.table ? "#{column.table}.#{column.name}" : column.name
      raise SqlError, "no such column: #{written}"
    end

    def alias_for(name)
      @aliases[Sql.fold(name)]
    end
  end

  # Checks every name and function in an expression, before any row is read, and returns the
  # expression with columns resolved (ColumnRef) and functions looked up.
  module Binder
    module_function

    def bind(node, scope)
      case node
      when Literal, ColumnRef, AggRef then node
      when Column then scope.resolve(node)
      when Unary then Unary.new(node.op, bind(node.operand, scope))
      when Binary then Binary.new(node.op, bind(node.left, scope), bind(node.right, scope))
      when Call then bind_call(node, scope)
      when Case
        Case.new(node.operand && bind(node.operand, scope),
                 node.whens.map { |c, r| [bind(c, scope), bind(r, scope)] },
                 node.else_expr && bind(node.else_expr, scope))
      when Between
        Between.new(bind(node.expr, scope), bind(node.low, scope), bind(node.high, scope), node.negated)
      when In then In.new(bind(node.expr, scope), node.list.map { |e| bind(e, scope) }, node.negated)
      when Like then Like.new(bind(node.expr, scope), bind(node.pattern, scope), node.negated)
      when Cast then Cast.new(bind(node.expr, scope), node.type)
      else
        raise "cannot bind #{node.inspect}"
      end
    end

    def bind_call(call, scope)
      return bind_aggregate(call, scope) if Aggregates.aggregate_call?(call)
      raise SyntaxError if call.star || call.distinct || !call.order_by.empty?
      fn = Functions.lookup(call.name, call.args.length)
      Call.new(name: call.name, args: call.args.map { |a| bind(a, scope) }, fn: fn)
    end

    def bind_aggregate(call, scope)
      inner = scope.for_aggregate_arguments
      args = call.args.map { |a| bind(a, inner) }
      order_by = call.order_by.map { |t| Ordering::SortKey.new(nil, bind(t.expr, inner), t.desc, t.nulls) }
      scope.aggregates.add(Aggregates.spec_for(call, args, order_by), call.name)
    end
  end
end

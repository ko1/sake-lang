# frozen_string_literal: true

require_relative "aggregate_slots"
require_relative "aggregates"
require_relative "ast"
require_relative "error"
require_relative "functions"
require_relative "schema"

module Sql
  # Checks the names in an expression (columns, aliases, functions) and rewrites column
  # references to ResolvedColumn. aliases maps a folded result-column alias to that column's
  # already resolved expression, which a reference to the alias stands for.
  #
  # mode says where the expression is and so what an aggregate call in it means: :allow (result
  # columns, HAVING, ORDER BY of an aggregate query; calls are added to slots), or an error
  # in :where (also UPDATE, DELETE, VALUES, LIMIT), :group_by and :order (ORDER BY of a plain query).
  class Resolver
    def initialize(columns, aliases, mode = :where, slots = nil)
      @columns = columns
      @aliases = aliases
      @mode = mode
      @slots = slots
    end

    def resolve(expr)
      case expr
      when Ast::ColumnRef then resolve_name(expr.name)
      when Ast::Unary then Ast::Unary.new(expr.op, resolve(expr.operand))
      when Ast::Binary then Ast::Binary.new(expr.op, resolve(expr.left), resolve(expr.right))
      when Ast::Is then Ast::Is.new(resolve(expr.left), resolve(expr.right), expr.negated)
      when Ast::FunctionCall then resolve_call(expr)
      when Ast::CaseExpr then resolve_case(expr)
      when Ast::Between then Ast::Between.new(resolve(expr.value), resolve(expr.low), resolve(expr.high), expr.negated)
      when Ast::InList then Ast::InList.new(resolve(expr.value), expr.candidates.map { |e| resolve(e) }, expr.negated)
      when Ast::Like then Ast::Like.new(resolve(expr.value), resolve(expr.pattern), expr.negated)
      when Ast::Cast then Ast::Cast.new(resolve(expr.operand), expr.type)
      else expr
      end
    end

    private

    def resolve_name(name)
      key = Names.fold(name)
      index = @columns.index { |column| Names.fold(column.name) == key }
      return Ast::ResolvedColumn.new(index, (@columns.fetch(index)).type) if index

      aliased = @aliases[key] || raise(Error, "no such column: #{name}")
      call = aliased.first_aggregate
      reject_aggregate(call.name, true) if call && @mode != :allow
      aliased
    end

    # Raises the error for an aggregate call (or, by_alias, a reference to a result column
    # holding one) in a place that does not allow it.
    def reject_aggregate(name, by_alias)
      raise Error, "aggregate functions are not allowed in the GROUP BY clause" if @mode == :group_by

      raise Error, by_alias || @mode == :order ? "misuse of aggregate: #{name}()" : "misuse of aggregate function #{name}()"
    end

    def resolve_case(expr)
      subject = expr.subject
      whens = expr.whens.map { |w| Ast::WhenClause.new(resolve(w.condition), resolve(w.result)) }
      else_result = expr.else_result
      Ast::CaseExpr.new(subject ? resolve(subject) : nil, whens, else_result ? resolve(else_result) : nil)
    end

    def resolve_call(call)
      function = Names.fold(call.name)
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
      return reject_aggregate(call.name, false) unless slots && @mode == :allow

      inner = argument_resolver
      args = call.args.map { |arg| inner.resolve(arg) }
      order_by = call.order_by.map { |term| Ast::OrderTerm.new(inner.resolve(term.expr), term.descending, term.nulls_first) }
      slots.add(call.name, function, args, call.distinct, call.star, order_by)
    end

    # Arguments of an aggregate are evaluated per row, so no aggregate may appear in them.
    def argument_resolver
      Resolver.new(@columns, @aliases, :where)
    end
  end
end

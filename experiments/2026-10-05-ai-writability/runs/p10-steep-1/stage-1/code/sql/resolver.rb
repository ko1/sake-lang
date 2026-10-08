# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "functions"
require_relative "schema"

module Sql
  # Checks the names in an expression (columns, aliases, functions) and rewrites column
  # references to ResolvedColumn. aliases maps a folded result-column alias to that column's
  # already resolved expression, which a reference to the alias stands for.
  class Resolver
    def initialize(columns, aliases)
      @columns = columns
      @aliases = aliases
    end

    def resolve(expr)
      case expr
      when Ast::ColumnRef then resolve_name(expr.name)
      when Ast::Unary then Ast::Unary.new(expr.op, resolve(expr.operand))
      when Ast::Binary then Ast::Binary.new(expr.op, resolve(expr.left), resolve(expr.right))
      when Ast::Is then Ast::Is.new(resolve(expr.left), resolve(expr.right), expr.negated)
      when Ast::FunctionCall then resolve_call(expr)
      else expr
      end
    end

    private

    def resolve_name(name)
      key = Names.fold(name)
      index = @columns.index { |column| Names.fold(column.name) == key }
      return Ast::ResolvedColumn.new(index, (@columns.fetch(index)).type) if index

      @aliases[key] || raise(Error, "no such column: #{name}")
    end

    def resolve_call(call)
      spec = Functions.lookup(call.name)
      raise Error, "no such function: #{call.name}" unless spec
      raise Error, "wrong number of arguments to function #{call.name}()" unless spec.accepts?(call.args.length)

      Ast::FunctionCall.new(call.name, call.args.map { |arg| resolve(arg) })
    end
  end
end

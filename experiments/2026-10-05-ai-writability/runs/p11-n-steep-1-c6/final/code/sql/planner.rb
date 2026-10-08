# frozen_string_literal: true

require_relative "ast"
require_relative "catalog"
require_relative "compound_plan"
require_relative "error"
require_relative "namespace"
require_relative "recursive_plan"
require_relative "schema"
require_relative "select_plan"

module Sql
  # Turns a parsed query into a plan: binds its WITH tables and plans its body.
  module Planner
    # parent is the scope of the enclosing query (nil at the top level and for a source of FROM).
    def self.build(query, namespace, parent)
      plan_body(query.body, bind_ctes(query, namespace), parent)
    end

    def self.plan_body(body, namespace, parent)
      case body
      when Ast::Select then SelectPlan.build(body, namespace, parent)
      when Ast::Compound then CompoundPlan.build(body, namespace, parent)
      else raise Error, "internal error: unknown query"
      end
    end

    # The namespace after the query's WITH tables, each seeing those before it.
    def self.bind_ctes(query, namespace)
      seen = {} #: Hash[String, bool]
      query.ctes.each do |definition|
        key = Names.fold(definition.name)
        raise Error, "duplicate WITH table name: #{definition.name}" if seen.key?(key)

        seen[key] = true
        recursive = query.recursive && self_referencing?(definition)
        namespace = namespace.with_cte(Cte.new(definition.name, definition.columns, definition.query, recursive, namespace))
      end
      namespace
    end

    # The plan of a WITH table's rows.
    def self.plan_cte(cte)
      body = cte.query.body
      return build(cte.query, cte.env, nil) unless cte.recursive && body.is_a?(Ast::Compound)

      RecursivePlan.build(cte, body, bind_ctes(cte.query, cte.env))
    end

    # The plan of a view's select, which sees the stored tables only.
    def self.plan_view(view, catalog)
      build(view.query, Namespace.new(catalog), nil)
    end

    # Whether the last select of a compound query FROM-mentions the WITH table itself.
    def self.self_referencing?(definition)
      body = definition.query.body
      return false unless body.is_a?(Ast::Compound)

      from = body.parts.fetch(body.parts.length - 1).from
      return false unless from

      key = Names.fold(definition.name)
      ([from.first] + from.joins.map(&:item)).any? { |item| item.is_a?(Ast::TableSource) && Names.fold(item.table) == key }
    end
  end
end

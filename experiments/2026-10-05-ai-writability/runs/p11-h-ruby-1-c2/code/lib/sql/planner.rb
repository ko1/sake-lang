# frozen_string_literal: true

require_relative "ast"
require_relative "catalog"
require_relative "compound_query"
require_relative "cte"
require_relative "errors"
require_relative "identifier"
require_relative "query"

module Sql
  # Turns a query node (Select, Compound, WithQuery) into something that can run, and says what a
  # name in a FROM means: a cte of an enclosing WITH, else a view, else a table. A planner is
  # immutable; a WITH makes a new one that also sees its ctes.
  class Planner
    def initialize(catalog, ctes = {})
      @catalog = catalog
      @ctes = ctes # folded name => something with #target
    end

    # parent: the Scope of the enclosing query when this is a subquery in an expression.
    def plan(node, parent = nil)
      case node
      when Select then Query.new(self, node, parent)
      when Compound then CompoundQuery.new(self, node, parent)
      when WithQuery then with_ctes(node).plan(node.body, parent)
      else raise "cannot plan #{node.inspect}"
      end
    end

    # What Scope calls: ->(select, enclosing_scope_or_nil) { query }.
    def call(node, parent)
      plan(node, parent)
    end

    # A Table (or WorkingTable: it has `rows`) to read, or a planned query (view, cte) to run.
    def resolve(name)
      binding = @ctes[Sql.fold(name)]
      return binding.target if binding
      relation = @catalog.relation(name) or raise SqlError, "no such table: #{name}"
      relation.is_a?(View) ? plan_view(relation) : relation
    end

    def with_binding(name, binding)
      Planner.new(@catalog, @ctes.merge(Sql.fold(name) => binding))
    end

    private

    def plan_view(view)
      # a view sees the database, not the ctes of the statement using it
      query = Planner.new(@catalog).plan(view.select, nil)
      NamedColumns.wrap(query, view.columns, view.name)
    end

    # The planner that also sees the ctes of a WithQuery, each seeing the ones before it.
    def with_ctes(with)
      seen = {}
      with.ctes.each do |cte|
        key = Sql.fold(cte.name)
        raise SqlError, "duplicate WITH table name: #{cte.name}" if seen[key]
        seen[key] = true
      end
      with.ctes.reduce(self) do |planner, cte|
        planner.with_binding(cte.name, CteBinding.new(cte, with.recursive, planner))
      end
    end
  end
end

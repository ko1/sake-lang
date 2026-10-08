# frozen_string_literal: true

require_relative 'ast'
require_relative 'compound_query'
require_relative 'errors'
require_relative 'namespace'
require_relative 'recursive_query'
require_relative 'select_query'

module SQL
  # Turns the AST of a query (Select, Compound or WithClause) into a planned query object
  # (see Query). Sits above SelectQuery, which needs it back for subqueries (lookups are at run time).
  module QueryPlanner
    module_function

    # `parent` is the Scope of the clause containing the query when it is a subquery (4.3).
    def plan(ast, namespace, parent: nil)
      case ast
      when Select then SelectQuery.new(ast, namespace, parent:)
      when Compound then CompoundQuery.new(ast, namespace, parent:)
      when WithClause then plan(ast.body, bind_ctes(ast, namespace), parent:)
      else raise ArgumentError, "not a query: #{ast.inspect}"
      end
    end

    # The namespace in which the body of `with` runs: each cte sees those before it.
    def bind_ctes(with, namespace)
      seen = {}
      with.ctes.reduce(namespace) do |ns, cte|
        raise SqlError, "duplicate WITH table name: #{cte.name}" if seen.key?(cte.name.downcase)

        seen[cte.name.downcase] = true
        query = with.recursive && recursive_form?(cte) ? RecursiveQuery.new(cte, ns) : plan(cte.query, ns)
        ns.with_cte(cte.name, Relation.from_query(cte.name, query, cte.columns))
      end
    end

    # `initial UNION [ALL] recursive` whose recursive select has the cte in its FROM.
    def recursive_form?(cte)
      q = cte.query
      q.is_a?(Compound) && %i[union union_all].include?(q.op) && q.left.is_a?(Select) &&
        q.right.is_a?(Select) && mentions?(q.right.from, cte.name)
    end

    def mentions?(from, name)
      case from
      when TableSource then from.name.casecmp?(name)
      when Join then mentions?(from.left, name) || mentions?(from.right, name)
      else false
      end
    end
  end
end

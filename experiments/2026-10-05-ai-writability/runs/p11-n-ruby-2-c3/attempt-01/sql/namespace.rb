# frozen_string_literal: true

require_relative 'errors'
require_relative 'scope'

module SQL
  # A named row source a FROM clause can read: `columns` are SourceColumns (copy them before use),
  # `rows` is a lambda giving the current rows.
  Relation = Data.define(:name, :columns, :rows) do
    def self.for_table(table)
      new(table.name, SQL.table_source_columns(table), -> { table.rows })
    end

    # A relation over a planned query; `names` (or nil) replaces the query's column names (5.2, 5.3).
    def self.from_query(name, query, names = nil)
      columns = query.result_names.zip(query.affinities).each_with_index.map do |(n, affinity), i|
        SourceColumn.new(names&.[](i) || n, affinity, false)
      end
      new(name, columns, -> { query.result_rows })
    end
  end

  # What a table name in a query means: a WITH table in scope (5.2), else a table or a view of the
  # catalog. Immutable: `with_cte` gives the namespace seen by the ctes after one and by the select.
  class Namespace
    attr_reader :catalog

    def initialize(catalog, ctes = {})
      @catalog = catalog
      @ctes = ctes
    end

    def with_cte(name, relation) = Namespace.new(@catalog, @ctes.merge(name.downcase => relation))

    def relation(name)
      @ctes[name.downcase] || table_or_view_relation(name) || raise(SqlError, "no such table: #{name}")
    end

    private

    # A view is planned anew by each statement that uses it, outside the statement's WITH tables.
    def table_or_view_relation(name)
      if (table = @catalog.find(name))
        Relation.for_table(table)
      elsif (view = @catalog.find_view(name))
        query = QueryPlanner.plan(view.query, Namespace.new(@catalog))
        Relation.from_query(view.name, query, view.columns)
      end
    end
  end
end

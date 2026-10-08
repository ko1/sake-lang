require_relative "errors"
require_relative "ast"

# The named sources a FROM can mention: the ctes of the WITH clauses around it (5.2), innermost
# first, then the database's views and tables (Database#relation). An entry's bind(outer), outer being
# the Binder of the clause whose FROM mentions it, gives the relation the FromClause reads: a Table,
# a NamedSource (a view or cte), or a RecursiveQuery::Working.
class Catalog
  # entries: name => entry.
  def initialize(parent, entries)
    @parent = parent
    @entries = entries.transform_keys(&:downcase)
  end

  def relation(name) = @entries[name.downcase] || @parent.relation(name)

  # The catalog a With's body sees: each cte sees the ones before it (and itself if recursive).
  # outer: the Binder of the clause enclosing the query that has the WITH.
  def self.with(with, parent, outer)
    seen = {}
    with.ctes.reduce(parent) do |catalog, cte|
      raise SqlError, "duplicate WITH table name: #{cte.name}" if seen[cte.name.downcase]
      seen[cte.name.downcase] = true
      recursive = with.recursive && AST.mentions?(cte.select, cte.name)
      Catalog.new(catalog, cte.name => CteSource.new(cte, catalog, outer, recursive))
    end
  end

  # A cte's column names: its list, else those of its select (4.1). The list must fit the select.
  def self.column_names(cte, query)
    return query.column_names unless cte.columns
    unless cte.columns.length == query.column_names.length
      raise SqlError, "table #{cte.name} has #{query.column_names.length} values for #{cte.columns.length} columns"
    end
    cte.columns
  end

  # The number of queries around a clause's query, -1 for no clause (the top).
  def self.depth(binder) = binder ? binder.depth : -1

  # A cte: its select is bound anew wherever the cte is used, in the scope of its definition.
  class CteSource
    def initialize(cte, catalog, outer, recursive)
      @cte = cte
      @catalog = catalog
      @outer = outer
      @recursive = recursive
    end

    def bind(outer)
      query = @recursive ? RecursiveQuery.new(@cte, @catalog, @outer) : Query.build(@cte.select, @catalog, @outer)
      names = @recursive ? query.column_names : Catalog.column_names(@cte, query)
      NamedSource.new(query, names, Catalog.depth(outer) - Catalog.depth(@outer))
    end
  end

  # A view (5.3): its select is bound anew, against the database alone, wherever it is used.
  class ViewSource
    def initialize(view, database)
      @view = view
      @database = database
    end

    def bind(_outer)
      query = @database.expanding(@view) { Query.build(@view.select, @database) }
      names = @view.columns || query.column_names
      unless names.length == query.column_names.length
        raise SqlError, "expected #{names.length} columns for '#{@view.name}' but got #{query.column_names.length}"
      end
      NamedSource.new(query, names, nil)
    end
  end

  # A bound view or cte as a relation. Its query was bound `levels` queries further out than where
  # it is used (nil: at the top, for a view), so it runs on the Frame that many levels out.
  class NamedSource
    attr_reader :column_names

    def initialize(query, column_names, levels)
      @query = query
      @column_names = column_names
      @levels = levels
    end

    def affinities = @query.affinities

    def rows(outer = nil)
      frame = @levels ? (0...@levels).reduce(outer) { |f, _| f&.outer } : nil
      @query.rows(frame)
    end
  end
end

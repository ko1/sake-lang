# frozen_string_literal: true

require_relative "ast"
require_relative "catalog"
require_relative "schema"

module Sql
  # The rows a recursive WITH table's recursive part reads: the one row being expanded.
  class RowFeed
    attr_accessor :rows

    def initialize
      @rows = [] #: Array[Array[value]]
    end
  end

  # A WITH table: its select is planned where the table is used, seeing the names of env (those
  # visible where the WITH table was written, so not itself). recursive tells that its select is
  # an initial select, UNION [ALL] and a recursive select that FROM-mentions the table.
  class Cte
    attr_reader :name, :column_names, :query, :recursive, :env

    def initialize(name, column_names, query, recursive, env)
      @name = name
      @column_names = column_names
      @query = query
      @recursive = recursive
      @env = env
    end
  end

  # What a recursive WITH table's own name stands for inside its recursive select.
  class WorkingTable
    attr_reader :name, :column_names, :feed

    def initialize(name, column_names, feed)
      @name = name
      @column_names = column_names
      @feed = feed
    end
  end

  # The names a FROM item can refer to in one place of a statement: the WITH tables in view
  # (hiding stored tables and views of the same name), then the catalog.
  class Namespace
    attr_reader :catalog

    def initialize(catalog, local = {})
      @catalog = catalog
      @local = local
    end

    # The WITH table or working table called name, if one is in view.
    def lookup(name)
      @local[Names.fold(name)]
    end

    def with_cte(cte)
      with_local(cte.name, cte)
    end

    def with_working_table(working)
      with_local(working.name, working)
    end

    private

    def with_local(name, entry)
      Namespace.new(@catalog, @local.merge(Names.fold(name) => entry))
    end
  end
end

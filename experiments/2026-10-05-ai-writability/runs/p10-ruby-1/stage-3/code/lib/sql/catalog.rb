# frozen_string_literal: true

require_relative "errors"
require_relative "identifier"
require_relative "table"

module Sql
  # The in-memory database: tables by folded name.
  class Catalog
    def initialize
      @tables = {}
    end

    def table(name)
      @tables[Sql.fold(name)]
    end

    def fetch_table(name)
      table(name) or raise SqlError, "no such table: #{name}"
    end

    def add(table)
      @tables[Sql.fold(table.name)] = table
    end

    def drop(name)
      @tables.delete(Sql.fold(name))
    end
  end
end

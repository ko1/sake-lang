# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "schema"
require_relative "table"

module Sql
  # A stored select, run anew wherever the view is used. name is as it was created.
  class View
    attr_reader :name, :column_names, :query

    def initialize(name, column_names, query)
      @name = name
      @column_names = column_names
      @query = query
    end
  end

  # What the catalog knows of an index: a UNIQUE index's constraint lives in its table.
  class Index
    attr_reader :name, :table_name, :unique

    def initialize(name, table_name, unique)
      @name = name
      @table_name = table_name
      @unique = unique
    end

    # The same index after its table was renamed.
    def moved_to(new_table_name)
      Index.new(@name, new_table_name, @unique)
    end
  end

  # The database's schema objects. Tables and views share one name space, indexes have their own.
  # All names are looked up ignoring ASCII case.
  class Catalog
    def initialize(tables = {}, views = {}, indexes = {})
      @tables = tables
      @views = views
      @indexes = indexes
    end

    # A snapshot that later changes to this catalog (its tables included) do not reach.
    def copy
      Catalog.new(@tables.transform_values(&:copy), @views.dup, @indexes.dup)
    end

    def find(name)
      @tables[Names.fold(name)]
    end

    def fetch(name)
      find(name) || raise(Error, "no such table: #{name}")
    end

    def view(name)
      @views[Names.fold(name)]
    end

    def index(name)
      @indexes[Names.fold(name)]
    end

    # :table or :view if the name is taken by one, else nil.
    def relation_kind(name)
      if find(name) then :table
      elsif view(name) then :view
      end
    end

    # Whether a table, view or index has the name.
    def taken?(name)
      !relation_kind(name).nil? || !index(name).nil?
    end

    def add(table)
      @tables[Names.fold(table.name)] = table
    end

    # Removes a table and its indexes.
    def remove(name)
      key = Names.fold(name)
      @tables.delete(key)
      @indexes = @indexes.reject { |_, index| Names.fold(index.table_name) == key }
    end

    def add_view(view)
      @views[Names.fold(view.name)] = view
    end

    def remove_view(name)
      @views.delete(Names.fold(name))
    end

    def add_index(index)
      @indexes[Names.fold(index.name)] = index
    end

    def remove_index(name)
      @indexes.delete(Names.fold(name))
    end

    def rename_table(table, new_name)
      old_key = Names.fold(table.name)
      @tables.delete(old_key)
      table.rename_to(new_name)
      @tables[Names.fold(new_name)] = table
      @indexes = @indexes.transform_values { |index| Names.fold(index.table_name) == old_key ? index.moved_to(new_name) : index }
    end
  end
end

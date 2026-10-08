# frozen_string_literal: true

require_relative 'errors'
require_relative 'storage'

module SQL
  # A view: a named query (5.3). `name` is as created; `columns` is the list of names or nil.
  View = Struct.new(:name, :columns, :query)

  # All tables, views and indexes of the database, looked up case-insensitively, and the open
  # transaction (5.5). Tables and views share a name space; indexes (kept by their table) have their own.
  class Catalog
    def initialize
      @tables = {}
      @views = {}
      @saved = nil # [tables, views] as of BEGIN while a transaction is open
    end

    def find(name) = @tables[name.downcase]

    def fetch(name) = find(name) || raise(SqlError, "no such table: #{name}")

    def add(table) = @tables[table.name.downcase] = table

    def drop(name) = @tables.delete(name.downcase)

    def rename(table, new_name)
      @tables.delete(table.name.downcase)
      table.rename_to(new_name)
      add(table)
    end

    def find_view(name) = @views[name.downcase]

    def add_view(view) = @views[view.name.downcase] = view

    def drop_view(name) = @views.delete(name.downcase)

    # [table, index] of the index called `name`, or nil.
    def find_index(name)
      @tables.each_value do |table|
        index = table.find_index(name)
        return [table, index] if index
      end
      nil
    end

    # --- transactions -------------------------------------------------------------------

    def begin_transaction
      raise SqlError, 'cannot start a transaction within a transaction' if @saved

      @saved = [@tables.transform_values(&:dup), @views.dup]
    end

    def commit
      raise SqlError, 'cannot commit - no transaction is active' unless @saved

      @saved = nil
    end

    def rollback
      raise SqlError, 'cannot rollback - no transaction is active' unless @saved

      @tables, @views = @saved
      @saved = nil
    end
  end
end

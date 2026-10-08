# frozen_string_literal: true

require_relative "ast"
require_relative "catalog"
require_relative "error"
require_relative "table"

module Sql
  # Statements that change the schema: tables, views and indexes. Each either completes or raises
  # without having changed the catalog.
  module Ddl
    def self.create_table(statement, catalog)
      return unless claim_name(statement.name, statement.if_not_exists, catalog)

      catalog.add(Table.from_statement(statement))
    end

    def self.create_view(statement, catalog)
      return unless claim_name(statement.name, statement.if_not_exists, catalog)

      catalog.add_view(View.new(statement.name, statement.columns, statement.query))
    end

    # Whether a new table or view may take the name; false (without error) if it is taken and the
    # statement says IF NOT EXISTS.
    def self.claim_name(name, if_not_exists, catalog)
      kind = catalog.relation_kind(name)
      if kind
        return false if if_not_exists

        raise Error, "#{kind} #{name} already exists"
      end
      raise Error, "there is already an index named #{name}" if catalog.index(name)

      true
    end
    private_class_method :claim_name

    def self.drop_table(statement, catalog)
      view = catalog.view(statement.name)
      raise Error, "use DROP VIEW to delete view #{view.name}" if view

      table = catalog.find(statement.name)
      if table
        catalog.remove(statement.name)
      elsif !statement.if_exists
        raise Error, "no such table: #{statement.name}"
      end
    end

    def self.drop_view(statement, catalog)
      table = catalog.find(statement.name)
      raise Error, "use DROP TABLE to delete table #{table.name}" if table

      if catalog.view(statement.name)
        catalog.remove_view(statement.name)
      elsif !statement.if_exists
        raise Error, "no such view: #{statement.name}"
      end
    end

    def self.create_index(statement, catalog)
      table = catalog.fetch(statement.table)
      raise Error, "there is already a table named #{statement.name}" if catalog.relation_kind(statement.name)

      if catalog.index(statement.name)
        return if statement.if_not_exists

        raise Error, "index #{statement.name} already exists"
      end
      key = table.index_key(statement.columns)
      table.add_unique_index(statement.name, key) if statement.unique
      catalog.add_index(Index.new(statement.name, table.name, statement.unique))
    end

    def self.drop_index(statement, catalog)
      index = catalog.index(statement.name)
      unless index
        return if statement.if_exists

        raise Error, "no such index: #{statement.name}"
      end
      catalog.fetch(index.table_name).drop_unique_index(index.name)
      catalog.remove_index(index.name)
    end

    def self.add_column(statement, catalog)
      alter_target(statement.table, catalog).add_column(statement.column)
    end

    def self.rename_table(statement, catalog)
      table = alter_target(statement.table, catalog)
      raise Error, "there is already another table or index with this name: #{statement.new_name}" if catalog.taken?(statement.new_name)

      catalog.rename_table(table, statement.new_name)
    end

    def self.rename_column(statement, catalog)
      alter_target(statement.table, catalog).rename_column(statement.column, statement.new_name)
    end

    # The table an ALTER TABLE changes.
    def self.alter_target(name, catalog)
      view = catalog.view(name)
      raise Error, "view #{view.name} may not be altered" if view

      catalog.fetch(name)
    end
    private_class_method :alter_target
  end
end

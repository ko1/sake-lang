# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "evaluator"
require_relative "resolver"
require_relative "scope"
require_relative "schema"
require_relative "table"
require_relative "value"

module Sql
  # INSERT, UPDATE and DELETE. The table checks constraints and applies each statement all or nothing.
  module Modify
    def self.insert(statement, catalog)
      table = catalog.fetch(statement.table)
      width = statement.rows.fetch(0).length
      raise Error, "all VALUES must have the same number of terms" unless statement.rows.all? { |row| row.length == width }

      targets = insert_targets(statement, table)
      if statement.columns
        raise Error, "#{width} values for #{targets.length} columns" if width != targets.length
      elsif width != targets.length
        raise Error, "table #{statement.table} has #{targets.length} columns but #{width} values were supplied"
      end
      constants = Resolver.new(Scope.new(catalog, [], nil), {})
      new_rows = statement.rows.map do |exprs|
        row = table.default_row
        exprs.each_with_index { |expr, i| row[targets.fetch(i)] = Evaluator.evaluate(constants.resolve(expr), []) }
        row
      end
      table.insert_rows(new_rows)
    end

    # The column positions the VALUES of each row go to.
    def self.insert_targets(statement, table)
      names = statement.columns
      return (0...table.columns.length).to_a unless names

      names.map do |column|
        table.column_index(column) || raise(Error, "table #{statement.table} has no column named #{column}")
      end
    end

    def self.update(statement, catalog)
      table = catalog.fetch(statement.table)
      scope = target_resolver(table, catalog)
      assignments = [] #: Array[[Integer, Ast::Expr]]
      statement.assignments.each do |assignment|
        position = table.column_index(assignment.column) || raise(Error, "no such column: #{assignment.column}")
        assignments << [position, scope.resolve(assignment.expr)]
      end
      where = statement.where ? scope.resolve(statement.where) : nil
      changes = [] #: Array[[Integer, Array[value]]]
      table.rows.each_with_index do |row, i|
        next unless matches?(where, row)

        updated = row.dup
        assignments.each { |position, expr| updated[position] = Evaluator.evaluate(expr, row) }
        changes << [i, updated]
      end
      table.update_rows(changes)
    end

    def self.delete(statement, catalog)
      table = catalog.fetch(statement.table)
      where = statement.where ? target_resolver(table, catalog).resolve(statement.where) : nil
      table.delete_rows(table.rows.map { |row| matches?(where, row) })
    end

    # Resolves names against the table being changed, which subqueries see as an enclosing source.
    def self.target_resolver(table, catalog)
      names = table.columns.map(&:name) #: Array[String?]
      types = table.columns.map(&:type) #: Array[column_type?]
      source = Source.new(table.name, names, types, 0, Array.new(names.length, false))
      Resolver.new(Scope.new(catalog, [source], nil), {})
    end

    # Whether a WHERE (nil: none) is true for the row.
    def self.matches?(where, row)
      where.nil? || Value.truth(Evaluator.evaluate(where, row)) == true
    end
  end
end

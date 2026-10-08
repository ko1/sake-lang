# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "catalog"
require_relative "evaluator"
require_relative "namespace"
require_relative "planner"
require_relative "resolver"
require_relative "scope"
require_relative "schema"
require_relative "table"
require_relative "value"

module Sql
  # INSERT, UPDATE and DELETE. The table checks constraints and applies each statement all or nothing.
  module Modify
    def self.insert(statement, catalog)
      table = target_table(catalog, statement.table)
      query = statement.query
      if query
        plan = Planner.build(query, Namespace.new(catalog), nil)
        targets = insert_targets(statement, table)
        check_insert_width(statement, targets, plan.column_count)
        selected = Query.result_rows(plan, [])
        table.insert_rows(selected.map { |values| insert_row(table, targets, values) })
        return
      end

      width = statement.rows.fetch(0).length
      raise Error, "all VALUES must have the same number of terms" unless statement.rows.all? { |row| row.length == width }

      targets = insert_targets(statement, table)
      check_insert_width(statement, targets, width)
      constants = Resolver.new(Scope.new(Namespace.new(catalog), [], nil), {})
      new_rows = statement.rows.map do |exprs|
        insert_row(table, targets, exprs.map { |expr| Evaluator.evaluate(constants.resolve(expr), []) })
      end
      table.insert_rows(new_rows)
    end

    # Raises if the INSERT gives width values for a different number of columns.
    def self.check_insert_width(statement, targets, width)
      return if width == targets.length

      if statement.columns
        raise Error, "#{width} values for #{targets.length} columns"
      else
        raise Error, "table #{statement.table} has #{targets.length} columns but #{width} values were supplied"
      end
    end

    # A table row with the values in the target columns and the others at their defaults.
    def self.insert_row(table, targets, values)
      row = table.default_row
      values.each_with_index { |value, i| row[targets.fetch(i)] = value }
      row
    end

    # The table a statement changes; a view cannot be changed.
    def self.target_table(catalog, name)
      view = catalog.view(name)
      raise Error, "cannot modify #{view.name} because it is a view" if view

      catalog.fetch(name)
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
      table = target_table(catalog, statement.table)
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
      table = target_table(catalog, statement.table)
      where = statement.where ? target_resolver(table, catalog).resolve(statement.where) : nil
      table.delete_rows(table.rows.map { |row| matches?(where, row) })
    end

    # Resolves names against the table being changed, which subqueries see as an enclosing source.
    def self.target_resolver(table, catalog)
      names = table.columns.map(&:name) #: Array[String?]
      types = table.columns.map(&:type) #: Array[column_type?]
      collations = table.columns.map(&:collation) #: Array[collation]
      source = Source.new(table.name, names, types, collations, 0, Array.new(names.length, false))
      Resolver.new(Scope.new(Namespace.new(catalog), [source], nil), {})
    end

    # Whether a WHERE (nil: none) is true for the row.
    def self.matches?(where, row)
      where.nil? || Value.truth(Evaluator.evaluate(where, row)) == true
    end
  end
end

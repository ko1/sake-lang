# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "evaluator"
require_relative "lexer"
require_relative "parser"
require_relative "resolver"
require_relative "schema"
require_relative "select_plan"
require_relative "value"

module Sql
  # One in-memory database. execute runs a statement and returns the lines it prints.
  class Engine
    # A result row with the values its ORDER BY terms evaluate to and its input position.
    class Entry
      attr_reader :values, :keys, :index

      def initialize(values, keys, index)
        @values = values
        @keys = keys
        @index = index
      end
    end

    def initialize
      @catalog = Catalog.new
    end

    # Runs a whole script, writing each statement's output (or "Error: ...") to out.
    def run_script(source, out)
      Lexer.new(source).statements.each do |tokens|
        begin
          statement = Parser.new(tokens).parse_statement
          execute(statement).each { |line| out.puts(line) } if statement
        rescue Error => e
          out.puts("Error: #{e.message}")
        end
      end
    end

    def execute(statement)
      case statement
      when Ast::CreateTable then create_table(statement)
      when Ast::DropTable then drop_table(statement)
      when Ast::Insert then insert(statement)
      when Ast::Select then run_select(statement)
      else raise Error, "internal error: unknown statement"
      end
    end

    private

    NO_LINES = Array.new(0, "").freeze

    def create_table(statement)
      if @catalog.find(statement.name)
        return NO_LINES if statement.if_not_exists

        raise Error, "table #{statement.name} already exists"
      end
      seen = {} #: Hash[String, bool]
      columns = statement.columns.map do |definition|
        key = Names.fold(definition.name)
        raise Error, "duplicate column name: #{definition.name}" if seen.key?(key)

        seen[key] = true
        Column.new(definition.name, definition.type)
      end
      @catalog.add(Table.new(statement.name, columns))
      NO_LINES
    end

    def drop_table(statement)
      if @catalog.find(statement.name)
        @catalog.remove(statement.name)
      elsif !statement.if_exists
        raise Error, "no such table: #{statement.name}"
      end
      NO_LINES
    end

    def insert(statement)
      table = @catalog.fetch(statement.table)
      width = statement.rows.fetch(0).length
      raise Error, "all VALUES must have the same number of terms" unless statement.rows.all? { |row| row.length == width }

      targets = insert_targets(statement, table)
      if statement.columns
        raise Error, "#{width} values for #{targets.length} columns" if width != targets.length
      elsif width != targets.length
        raise Error, "table #{statement.table} has #{targets.length} columns but #{width} values were supplied"
      end
      constants = Resolver.new([], {})
      resolved = statement.rows.map { |row| row.map { |expr| constants.resolve(expr) } }
      new_rows = resolved.map do |row|
        stored = Array.new(table.columns.length, nil) #: Array[value]
        row.each_with_index do |expr, i|
          target = targets.fetch(i)
          stored[target] = table.columns.fetch(target).store(Evaluator.evaluate(expr, []), table.name)
        end
        stored
      end
      table.append_rows(new_rows)
      NO_LINES
    end

    # The column positions the VALUES of each row go to.
    def insert_targets(statement, table)
      names = statement.columns
      return (0...table.columns.length).to_a unless names

      names.map do |column|
        table.column_index(column) || raise(Error, "table #{statement.table} has no column named #{column}")
      end
    end

    def run_select(statement)
      table = statement.table ? @catalog.fetch(statement.table) : nil
      plan = SelectPlan.build(statement, table)
      limit = bound(plan.limit)
      offset = bound(plan.offset)
      rows = table ? table.rows : [[]] #: Array[Array[value]]
      where = plan.where
      rows = rows.select { |row| Value.truth(Evaluator.evaluate(where, row)) == true } if where
      entries = rows.each_with_index.map do |row, i|
        Entry.new(plan.results.map { |expr| Evaluator.evaluate(expr, row) },
                  plan.order_by.map { |term| Evaluator.evaluate(term.expr, row) }, i)
      end
      entries = entries.sort { |a, b| compare_entries(a, b, plan.order_by) } unless plan.order_by.empty?
      entries = entries.drop([offset || 0, 0].max)
      entries = entries.first(limit) if limit && limit >= 0
      entries.map { |entry| entry.values.map { |v| v.nil? ? "NULL" : Value.text_form(v) }.join("|") }
    end

    # The integer a LIMIT or OFFSET expression evaluates to, or nil without one.
    def bound(expr)
      return nil unless expr

      value = Evaluator.evaluate(expr, [])
      return nil if value.nil?

      Value.to_number(value).to_i
    end

    def compare_entries(left, right, terms)
      terms.each_with_index do |term, i|
        c = compare_keys(left.keys.fetch(i), right.keys.fetch(i), term)
        return c unless c == 0
      end
      left.index < right.index ? -1 : 1
    end

    def compare_keys(a, b, term)
      return 0 if a.nil? && b.nil?

      if a.nil? || b.nil?
        nulls_first = term.nulls_first.nil? ? !term.descending : term.nulls_first
        return a.nil? == nulls_first ? -1 : 1
      end
      c = Value.compare(a, b)
      term.descending ? -c : c
    end
  end
end

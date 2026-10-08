# frozen_string_literal: true

require_relative "aggregates"
require_relative "ast"
require_relative "errors"
require_relative "identifier"
require_relative "windows"

module Sql
  # A column of a source: its name as written (nil: cannot be referred to), affinity type (nil: none)
  # and collation (7.5; every column has one, :binary if none was given).
  SourceColumn = Data.define(:name, :type, :collation) do
    def initialize(name:, type:, collation: :binary) = super
  end

  # One item of a FROM: `name` is its alias or table name (nil for a bare subquery); its columns sit at
  # `offset` in the joined row.
  Source = Data.define(:name, :columns, :offset)

  # Set when a name of an enclosing query is used, so the query must be run again for each outer row.
  class Correlation
    attr_accessor :used
  end

  # What names mean at one place in a statement. A query's row is its own sources' values side by side
  # (`width` of them), followed by the whole row of the enclosing query (`parent`): an outer column is
  # just a ColumnRef further right. Also here: the aliases of the result columns where the clause lets
  # a name mean one (already bound expressions), and what an aggregate call does (collected, or an error).
  class Scope
    NO_AGGREGATES = Aggregates::Forbidden.new("misuse of aggregate function %s()", "misuse of aggregate: %s()")

    attr_reader :aggregates, :windows, :sources, :width, :parent, :planner, :correlation

    # sources: the Sources visible here; width: values of all the query's sources (even those not yet
    # visible, while an ON is bound); hidden: indexes of columns that USING merged away;
    # planner: a Planner, to plan subqueries.
    def initialize(sources: [], width: sources.sum { |s| s.columns.length }, parent: nil, planner: nil,
                   hidden: [], aliases: {}, aggregates: NO_AGGREGATES, windows: Windows::FORBIDDEN,
                   correlation: Correlation.new)
      @sources = sources
      @width = width
      @parent = parent
      @planner = planner
      @hidden = hidden
      @aliases = aliases
      @aggregates = aggregates
      @windows = windows
      @correlation = correlation
    end

    # The scope of a statement's single target table (UPDATE, DELETE).
    def self.for_table(table, planner)
      columns = table.columns.map { |c| SourceColumn.new(c.name, c.type, c.collation) }
      new(sources: [Source.new(table.name, columns, 0)], planner: planner)
    end

    def with(**changes)
      Scope.new(sources: @sources, width: @width, parent: @parent, planner: @planner, hidden: @hidden,
                aliases: @aliases, aggregates: @aggregates, windows: @windows, correlation: @correlation, **changes)
    end

    # The scope of an aggregate call's arguments: the sources only, no aliases, no nested aggregates or windows.
    def for_aggregate_arguments
      with(aliases: {}, aggregates: NO_AGGREGATES, windows: Windows::FORBIDDEN)
    end

    # The scope of a window call's arguments and window-spec: the sources only, no aliases, no nested windows.
    def for_window_arguments
      with(aliases: {}, windows: Windows::FORBIDDEN)
    end

    # Length of a row seen here: own values, then the enclosing query's row.
    def row_width
      @width + (@parent ? @parent.row_width : 0)
    end

    # Does a name of an enclosing query get used (so far)?
    def correlated?
      @correlation.used
    end

    # Plans a subquery whose enclosing query is this scope.
    def plan_subquery(select)
      @planner.call(select, self)
    end

    # The bound expression a Column node stands for, or a name error.
    def resolve(column)
      found = find_in_sources(column)
      return found if found
      if column.table.nil? && (expr = @aliases[Sql.fold(column.name)])
        @aggregates.check_alias(expr)
        @windows.check_alias(expr, column.name)
        return expr
      end
      raise SqlError, "no such column: #{written(column)}" unless @parent
      outer = @parent.resolve(column)
      @correlation.used = true
      outer.is_a?(ColumnRef) ? ColumnRef.new(outer.index + @width, outer.type, outer.collation) : OuterExpr.new(outer, @width)
    end

    # The source of this query named `name`, or nil.
    def source_named(name)
      @sources.find { |s| s.name && Sql.fold(s.name) == Sql.fold(name) }
    end

    def visible?(index)
      !@hidden.include?(index)
    end

    private

    def find_in_sources(column)
      if column.table
        source = source_named(column.table) or return nil
        i = source.columns.index { |c| c.name && Sql.fold(c.name) == Sql.fold(column.name) }
        raise SqlError, "no such column: #{written(column)}" unless i
        return column_ref(source, i)
      end
      key = Sql.fold(column.name)
      matches = @sources.flat_map do |source|
        source.columns.each_index.select do |i|
          c = source.columns[i]
          c.name && Sql.fold(c.name) == key && visible?(source.offset + i)
        end.map { |i| [source, i] }
      end
      raise SqlError, "ambiguous column name: #{column.name}" if matches.length > 1
      matches.empty? ? nil : column_ref(*matches.first)
    end

    def column_ref(source, i)
      c = source.columns[i]
      ColumnRef.new(source.offset + i, c.type, c.collation)
    end

    def written(column)
      column.table ? "#{column.table}.#{column.name}" : column.name
    end
  end
end

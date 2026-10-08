# frozen_string_literal: true

require_relative 'errors'

module SQL
  # A column as a source offers it. `affinity` is :integer, :real, :text or nil (1.9); `hidden` is the
  # right side's copy of a USING column, which unqualified names and `*` skip (4.2).
  SourceColumn = Struct.new(:name, :affinity, :hidden)

  # One from-item (4.1). Its columns occupy `offset...offset + columns.size` of the joined row.
  # `name` is the alias or the table's name; nil for a subquery without alias.
  class Source
    attr_reader :name, :columns, :offset

    def self.for_table(table, name: table.name, offset: 0)
      new(name, table.columns.map { |c| SourceColumn.new(c.name, c.affinity, false) }, offset)
    end

    def initialize(name, columns, offset)
      @name = name
      @columns = columns
      @offset = offset
    end

    # Index of the column within the source, or nil.
    def find(column_name) = @columns.index { |c| c.name&.casecmp?(column_name) }
  end

  # The row of a query that is being evaluated, readable by the subqueries inside it (4.3).
  Frame = Struct.new(:row)

  # Set when a subquery refers to a name of a query around it, so it must run again for each row.
  Correlation = Struct.new(:flag)

  # The sources of one query, in the order of the joined row, plus what its subqueries need.
  class Level
    attr_reader :sources, :namespace, :parent, :frame, :correlation

    # `parent` is the Scope of the enclosing clause (nil at top level and for subquery sources).
    def initialize(sources, namespace, parent: nil, correlation: Correlation.new(false))
      @sources = sources
      @namespace = namespace
      @parent = parent
      @correlation = correlation
      @frame = Frame.new
    end

    def width = @sources.sum { |s| s.columns.size }

    def source_named(name) = @sources.find { |s| s.name&.casecmp?(name) }

    # [row index, SourceColumn] of every visible column called `name`.
    def visible_columns(name)
      @sources.flat_map do |s|
        s.columns.each_with_index.filter_map do |c, i|
          [s.offset + i, c] if !c.hidden && c.name&.casecmp?(name)
        end
      end
    end
  end

  # Where names are looked up while compiling one clause: the sources of a query (a Level) and,
  # optionally, result-column aliases (name -> expression) that a name falls back to when it is no
  # column. A name that matches nothing goes on to the enclosing query's scope (4.2).
  # `aggregates` maps a normalized aggregate Call (Aggregates.key) to the row slot holding its value;
  # nil where aggregate calls are not allowed, and `misuse` (:function, :plain, :group_by) picks
  # the error then (3.3). `windows` is the same for window calls (Windows.key), nil where they are not allowed (6.2).
  class Scope
    attr_reader :level, :aliases, :aggregates, :windows

    def self.empty(namespace) = new(Level.new([], namespace))

    # The scope of UPDATE / DELETE: the target table is the one source.
    def self.for_table(table, namespace) = new(Level.new([Source.for_table(table)], namespace))

    def initialize(level, aliases = {}, aggregates: nil, windows: nil, misuse: :function)
      @level = level
      @aliases = aliases
      @aggregates = aggregates
      @windows = windows
      @misuse = misuse
    end

    # The same scope for the body of an alias: names in it are columns only.
    def without_aliases = Scope.new(@level, {}, aggregates: @aggregates, windows: @windows, misuse: @misuse)

    def misuse_error(name, via_alias: false)
      case @misuse
      when :group_by then SqlError.new('aggregate functions are not allowed in the GROUP BY clause')
      when :plain then SqlError.new("misuse of aggregate: #{name}()")
      else SqlError.new(via_alias ? "misuse of aggregate: #{name}()" : "misuse of aggregate function #{name}()")
      end
    end
  end
end

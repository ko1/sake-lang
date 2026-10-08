# frozen_string_literal: true

require_relative "error"
require_relative "namespace"
require_relative "schema"

module Sql
  # Where a name was found: the position of the column in the row being read, its affinity (nil:
  # none) and its name (nil for a column of a subquery source that has none).
  class Location
    attr_reader :index, :type, :name

    def initialize(index, type, name)
      @index = index
      @type = type
      @name = name
    end

    # The same column seen from a query nested width columns further out.
    def shifted(width)
      Location.new(@index + width, @type, @name)
    end
  end

  # One source of a FROM as names see it: its columns sit at positions offset... of the row.
  # name is nil for a subquery without an alias. merged[i] marks the right-hand copy of a USING
  # column, which an unqualified name and * skip. A table's source (rowid: true) has one more
  # slot in its rows after the real columns: the hidden rowid (spec 7.1), which names and * never list.
  class Source
    attr_reader :name, :names, :types, :offset

    def initialize(name, names, types, offset, merged, rowid: false)
      @name = name
      @names = names
      @types = types
      @offset = offset
      @merged = merged
      @rowid = rowid
    end

    # The slots of the source in a row, the hidden rowid included.
    def width
      @names.length + (@rowid ? 1 : 0)
    end

    # The real columns only.
    def real_width
      @names.length
    end

    # Where the rowid is, or nil for a source that is not a table.
    def rowid_location
      @rowid ? Location.new(@offset + @names.length, :integer, nil) : nil
    end

    def merged?(position)
      @merged.fetch(position)
    end

    # The position in this source of the column with that name, or nil.
    def position_of(column_name)
      key = Names.fold(column_name)
      @names.index { |n| n && Names.fold(n) == key }
    end

    def location(position)
      Location.new(@offset + position, @types.fetch(position), @names.fetch(position))
    end
  end

  # The sources of one query, inside the scope of the query that contains it (parent). A query's
  # rows are its sources' columns in order, followed by the row of its parent (a subquery runs
  # against the row of the query around it), so a column found in the parent is at the parent's
  # position plus width.
  class Scope
    attr_reader :namespace, :sources, :parent

    def initialize(namespace, sources, parent)
      @namespace = namespace
      @sources = sources
      @parent = parent
    end

    # The columns of the sources only.
    def width
      @sources.sum(&:width)
    end

    # The columns the parent adds to a row.
    def outer_width
      parent = @parent
      parent ? parent.full_width : 0
    end

    def full_width
      width + outer_width
    end

    def with_source(source)
      Scope.new(@namespace, @sources + [source], @parent)
    end

    # The column called name of the first source (in FROM order) that has one, merged or not.
    def find_first(name)
      @sources.each do |source|
        position = source.position_of(name)
        return source.location(position) if position
      end
      nil
    end

    # The unqualified name among this query's own sources: nil if none has it; the error if
    # several do.
    def find_own(name)
      key = Names.fold(name)
      found = [] #: Array[Location]
      @sources.each do |source|
        source.names.each_with_index do |n, i|
          found << source.location(i) if n && Names.fold(n) == key && !source.merged?(i)
        end
      end
      raise Error, "ambiguous column name: #{name}" if found.length > 1

      found.first || find_own_rowid(name)
    end

    # A rowid name no source has as a real column: the rowid of the only source, if it is a table.
    def find_own_rowid(name)
      return nil unless Names.rowid?(name) && !@sources.empty?
      raise Error, "ambiguous column name: #{name}" if @sources.length > 1

      @sources.fetch(0).rowid_location
    end

    # The unqualified name in the enclosing queries, innermost first.
    def find_outer(name)
      parent = @parent
      location = parent ? parent.find_column(name) : nil
      location ? location.shifted(width) : nil
    end

    def find_column(name)
      find_own(name) || find_outer(name)
    end

    def find_source(name)
      key = Names.fold(name)
      @sources.find { |source| (n = source.name) && Names.fold(n) == key }
    end

    # q.name: the column of the innermost source called q, or nil if no source is called q.
    # Raises when that source lacks the column.
    def find_qualified(qualifier, name)
      source = find_source(qualifier)
      if source
        position = source.position_of(name)
        return source.location(position) if position

        return (Names.rowid?(name) ? source.rowid_location : nil) || raise(Error, "no such column: #{qualifier}.#{name}")
      end
      parent = @parent
      location = parent ? parent.find_qualified(qualifier, name) : nil
      location ? location.shifted(width) : nil
    end

    # The columns * (qualifier nil) or qualifier.* stands for; nil if no source is called qualifier.
    def star_columns(qualifier)
      if qualifier
        source = find_source(qualifier)
        return nil unless source

        return (0...source.real_width).map { |i| source.location(i) }
      end
      list = [] #: Array[Location]
      @sources.each do |source|
        (0...source.real_width).each { |i| list << source.location(i) unless source.merged?(i) }
      end
      list
    end
  end
end

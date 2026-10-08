module MiniSql
  # A column of a source: name is nil for a computed column of a subquery; affinity is nil when it has none;
  # collation is nil when the column has none (SPEC 7.3), and explicit tells whether it was written as COLLATE.
  class SourceColumn
    attr_reader :name, :affinity, :collation, :explicit

    def initialize(name, affinity, collation, explicit)
      @name = name
      @affinity = affinity
      @collation = collation
      @explicit = explicit
    end

    # The columns under the given names (a view's or cte's column list); nil keeps the names.
    def self.rename(columns, names)
      return columns unless names
      columns.each_with_index.map do |column, i|
        new(names.fetch(i, column.name), column.affinity, column.collation, column.explicit)
      end
    end

    def explicit_collation
      @explicit ? @collation : nil
    end

    def implicit_collation
      @explicit ? nil : @collation
    end

    # The collation the values of the column compare under among themselves.
    def value_collation
      @collation || :binary
    end
  end

  # One from-item of a FROM clause: its name (nil for an unnamed subquery), its columns and the position of
  # its first column in the joined row.
  class Source
    attr_reader :name, :columns, :offset

    def initialize(name, columns, offset)
      @name = name
      @columns = columns
      @offset = offset
    end

    # The rows of the source, each as wide as its columns.
    def rows
      raise NotImplementedError, "rows"
    end

    # Position in the joined row of the column called `name` (case-insensitive), or nil.
    def index_of(name)
      wanted = name.downcase(:ascii)
      position = @columns.index { |column| column.name&.downcase(:ascii) == wanted }
      position && @offset + position
    end
  end

  class TableSource < Source
    def initialize(name, table, offset)
      super(name, table.columns.map { |column| SourceColumn.new(column.name, column.type, column.collation, false) }, offset)
      @table = table
    end

    def rows
      @table.rows
    end
  end

  # A select used as a source (a subquery in FROM, a view, a cte): the select runs once per use. columns are the
  # plan's columns, possibly renamed.
  class DerivedSource < Source
    def initialize(name, plan, offset, columns)
      super(name, columns, offset)
      @plan = plan
    end

    def rows
      @plan.rows
    end
  end

  # The cte a recursive select reads: the row the working set holds now.
  class WorkingSource < Source
    def initialize(name, columns, offset, working)
      super(name, columns, offset)
      @working = working
    end

    def rows
      @working.rows
    end
  end

  # The sources of one query in FROM order: the layout of the joined row (the columns of every source, one
  # after the other) and name resolution against it (SPEC 4.2).
  class Sources
    attr_reader :sources, :width

    def initialize
      @sources = [] # @type ivar @sources: Array[Source]
      @width = 0
      @hidden = {} # @type ivar @hidden: Hash[Integer, bool]
    end

    def empty?
      @sources.empty?
    end

    def add(source)
      @sources << source
      @width += source.columns.length
    end

    # Leaves the column out of unqualified lookups and `*` (the right copy of a USING column).
    def hide(index)
      @hidden[index] = true
    end

    # Whether some source is called `name` (case-insensitive).
    def named?(name)
      @sources.any? { |source| called?(source, name) }
    end

    # The column `name` of the source `qualifier` (any source when nil), as a BoundColumn; nil if there is none,
    # SqlError if several sources have it.
    def find(qualifier, name)
      wanted = name.downcase(:ascii)
      found = [] # @type var found: Array[BoundColumn]
      @sources.each do |source|
        next if qualifier && !called?(source, qualifier)
        source.columns.each_with_index do |column, position|
          index = source.offset + position
          next if qualifier.nil? && @hidden[index]
          found << BoundColumn.new(index, column.affinity, column.value_collation) if column.name&.downcase(:ascii) == wanted
        end
      end
      raise SqlError, "ambiguous column name: #{name}" if found.length > 1
      found.first
    end

    # The affinity of the column at this position of the joined row.
    def affinity_at(index)
      column_at(index)&.affinity
    end

    # The collation of the column at this position of the joined row (:binary when it has none).
    def collation_at(index)
      column = column_at(index)
      column ? column.value_collation : :binary
    end

    # Position of the first column called `name` in any source, or nil.
    def first_index(name)
      @sources.each do |source|
        index = source.index_of(name)
        return index if index
      end
      nil
    end

    # The columns `*` (qualifier nil) or `qualifier.*` stands for, with their positions in the joined row.
    def expand(qualifier)
      pairs = [] # @type var pairs: Array[[Integer, SourceColumn]]
      matched = false
      @sources.each do |source|
        next if qualifier && !called?(source, qualifier)
        matched = true
        source.columns.each_with_index do |column, position|
          index = source.offset + position
          pairs << [index, column] unless qualifier.nil? && @hidden[index]
        end
      end
      raise SqlError, "no such table: #{qualifier}" if qualifier && !matched
      pairs
    end

    private

    def column_at(index)
      @sources.each do |source|
        column = source.columns[index - source.offset]
        return column if column && index >= source.offset
      end
      nil
    end

    def called?(source, name)
      source_name = source.name
      !source_name.nil? && source_name.downcase(:ascii) == name.downcase(:ascii)
    end
  end
end

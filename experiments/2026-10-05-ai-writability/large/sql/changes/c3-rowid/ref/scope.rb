require_relative "errors"

# The sources of one query's FROM as names see them (spec 4.2): each source's columns and where each
# column's value is in the joined row (the sources' rows side by side, in FROM order).
class Scope
  # affinity: a column type or nil (1.9); index: the position in the joined row; merged: the right
  # side's copy of a USING column, which unqualified names and `*` do not see.
  Column = Struct.new(:name, :affinity, :index, :merged)
  # name: the alias, the table's name, or nil for an unnamed subquery; rowid: a table's rowid (a
  # Column without a name, after the real columns in the joined row), else nil.
  Source = Struct.new(:name, :columns, :rowid)
  ROWID_NAMES = %w[rowid _rowid_ oid].freeze

  attr_reader :sources, :width

  def initialize(sources = [])
    @sources = sources
    @width = sources.sum { |source| source.columns.length + (source.rowid ? 1 : 0) }
  end

  def self.rowid_name?(name) = ROWID_NAMES.include?(name.downcase)

  # A scope with a source added on the right; its columns are given as [name, affinity], and those
  # named in `merged` (downcased) are the right copies of USING columns. rowid: the source is a table,
  # whose rows carry the rowid after the columns.
  def add(name, columns, merged: [], rowid: false)
    added = columns.each_with_index.map do |(column, affinity), i|
      Column.new(column, affinity, @width + i, merged.include?(column&.downcase))
    end
    hidden = rowid ? Column.new(nil, "INTEGER", @width + added.length, false) : nil
    Scope.new(@sources + [Source.new(name, added, hidden)])
  end

  def source(name)
    key = name.downcase
    @sources.find { |source| source.name&.downcase == key }
  end

  # The column `name` of each source that has one (the first if a source has two), leaving out merged
  # USING copies.
  def lookup(name)
    key = name.downcase
    @sources.filter_map { |source| Scope.column_in(source, key) }.reject(&:merged)
  end

  # The rowid an unqualified rowid name means when no source has a real column of that name (7.1):
  # nil when the name is no rowid name or there are no sources; raises with several sources.
  def rowid_lookup(name)
    return nil unless Scope.rowid_name?(name) && !@sources.empty?
    raise SqlError, "ambiguous column name: #{name}" if @sources.length > 1
    @sources[0].rowid
  end

  # The columns `*` stands for.
  def star
    @sources.flat_map(&:columns).reject(&:merged)
  end

  def self.column_in(source, key)
    source.columns.find { |column| column.name&.downcase == key }
  end

  # column_in, else the source's rowid for a rowid name (7.1).
  def self.column_or_rowid(source, key)
    column_in(source, key) || (ROWID_NAMES.include?(key) ? source.rowid : nil)
  end
end

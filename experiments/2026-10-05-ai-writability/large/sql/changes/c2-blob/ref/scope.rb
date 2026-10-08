require_relative "errors"

# The sources of one query's FROM as names see them (spec 4.2): each source's columns and where each
# column's value is in the joined row (the sources' rows side by side, in FROM order).
class Scope
  # affinity: a column type or nil (1.9); index: the position in the joined row; merged: the right
  # side's copy of a USING column, which unqualified names and `*` do not see.
  Column = Struct.new(:name, :affinity, :index, :merged)
  # name: the alias, the table's name, or nil for an unnamed subquery.
  Source = Struct.new(:name, :columns)

  attr_reader :sources, :width

  def initialize(sources = [])
    @sources = sources
    @width = sources.sum { |source| source.columns.length }
  end

  # A scope with a source added on the right; its columns are given as [name, affinity], and those
  # named in `merged` (downcased) are the right copies of USING columns.
  def add(name, columns, merged: [])
    added = columns.each_with_index.map do |(column, affinity), i|
      Column.new(column, affinity, @width + i, merged.include?(column&.downcase))
    end
    Scope.new(@sources + [Source.new(name, added)])
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

  # The columns `*` stands for.
  def star
    @sources.flat_map(&:columns).reject(&:merged)
  end

  def self.column_in(source, key)
    source.columns.find { |column| column.name&.downcase == key }
  end
end

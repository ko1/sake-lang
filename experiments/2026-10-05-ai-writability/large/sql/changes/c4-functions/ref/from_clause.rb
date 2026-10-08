require_relative "errors"
require_relative "ast"
require_relative "scope"
require_relative "expressions"

# A query's FROM (spec 4.1) bound: its Scope, and `rows`, the joined rows (arrays of the sources'
# values side by side). Without FROM there is one empty row.
class FromClause
  # source: a relation (see #source); left: a LEFT JOIN; condition: the bound ON
  # or USING condition, or nil; width: the source's column count.
  Join = Struct.new(:source, :left, :condition, :width)

  attr_reader :scope

  # outer: the Binder a subquery source looks up outer names in (that of the query enclosing this
  # one: a subquery source does not see the other sources of its FROM); binder_for: given a Scope,
  # the Binder for an ON condition over it.
  def initialize(from, catalog, outer, &binder_for)
    @catalog = catalog
    @outer = outer
    @scope = Scope.new
    @first = nil
    @joins = []
    return unless from
    @first, name, columns = source(from.first)
    @scope = @scope.add(name, columns)
    from.joins.each { |join| add_join(join, binder_for) }
  end

  # The joined rows; outer: the Frame subquery sources see as their enclosing row.
  def rows(outer)
    return [[]] unless @first
    @joins.reduce(@first.rows(outer)) do |rows, join|
      right = join.source.rows(outer)
      rows.flat_map do |left|
        matched = right.filter_map do |values|
          row = left + values
          row if join.condition.nil? || Values.truth(join.condition.evaluate(Expressions::Frame.new(row, outer)))
        end
        matched.empty? && join.left ? [left + Array.new(join.width)] : matched
      end
    end
  end

  private

  # [relation, name, [[column name, affinity]]] for a from-item. A relation is a Table or a bound
  # query (SelectQuery, CompoundQuery, a view or cte as Catalog binds it): its column_names,
  # affinities and rows(outer).
  def source(item)
    case item
    when AST::TableSource
      entry = @catalog.relation(item.table) or raise SqlError, "no such table: #{item.table}"
      relation = entry.bind(@outer)
      [relation, item.alias || item.table, relation.column_names.zip(relation.affinities)]
    when AST::SubquerySource
      query = Query.build(item.select, @catalog, @outer)
      [query, item.alias, query.column_names.zip(query.affinities)]
    end
  end

  # USING (c, ...) is `left.c = right.c AND ...`, left.c being the first source so far that has c;
  # the right copies are then merged into the left ones (4.2).
  def add_join(join, binder_for)
    source, name, columns = source(join.source)
    if join.using
      lefts = join.using.map { |c| using_left(c, columns) }
      @scope = @scope.add(name, columns, merged: join.using.map(&:downcase))
      condition = join.using.zip(lefts).map do |c, left|
        right = Scope.column_in(@scope.sources.last, c.downcase)
        Expressions::Comparison.new("=", column_ref(left), column_ref(right))
      end.reduce { |x, y| Expressions::And.new(x, y) }
    else
      @scope = @scope.add(name, columns)
      condition = join.on && binder_for.(@scope).bind(join.on)
    end
    @joins << Join.new(source, join.kind == :left, condition, columns.length)
  end

  # The left column for USING column `name`, after checking that the right source (`columns`) has it.
  def using_left(name, columns)
    key = name.downcase
    left = @scope.sources.lazy.filter_map { |source| Scope.column_in(source, key) }.first
    unless left && columns.any? { |column, _| column&.downcase == key }
      raise SqlError, "cannot join using column #{name} - column not present in both tables"
    end
    left
  end

  def column_ref(column) = Expressions::ColumnRef.new(column.index, column.affinity)
end

module MiniSql
  # The row a query is currently evaluating, shared with the subqueries inside it so that they can read the
  # columns of the enclosing query. Set by BoundSubquery just before it runs the subquery.
  class RowFrame
    attr_accessor :row

    def initialize
      @row = [] # @type ivar @row: Array[sql_value]
    end
  end

  # An enclosing query as its subqueries see it: its sources, the result column aliases its clause
  # allows (lower-case name => bound expression), its frame, and the query around it.
  class Outer
    attr_reader :sources, :aliases, :frame, :parent

    def initialize(sources, aliases, frame, parent)
      @sources = sources
      @aliases = aliases
      @frame = frame
      @parent = parent
    end
  end

  # What a Binder needs besides names: the database (to plan subqueries), the frame of the query
  # it binds for, that query's enclosing queries (nil for a top-level query) and the ctes it can see (nil: none).
  class Environment
    attr_reader :database, :frame, :outer, :ctes

    def initialize(database, frame, outer, ctes)
      @database = database
      @frame = frame
      @outer = outer
      @ctes = ctes
    end
  end
end

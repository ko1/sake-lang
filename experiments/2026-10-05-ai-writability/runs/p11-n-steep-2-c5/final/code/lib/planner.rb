module MiniSql
  # Plans any select: a simple one, a compound one (SPEC 5.1) or one with a WITH clause (SPEC 5.2).
  # The result is a Plan; every name or clause error is raised here, before any row is read.
  class Planner
    # outer: the enclosing queries when the select is a subquery of an expression, else nil; ctes: the
    # WITH tables it can see, else nil.
    def initialize(database, select, outer, ctes)
      @database = database
      @select = select
      @outer = outer
      @ctes = ctes
    end

    def plan
      select = @select
      case select
      when WithSelect
        scope = CtePlanner.new(@database, @outer, @ctes).scope_for(select.with)
        Planner.new(@database, select.body, @outer, scope).plan
      when CompoundSelect then CompoundPlanner.new(@database, select, @outer, @ctes).plan
      when Select then SimplePlanner.new(@database, select, @outer, @ctes).plan
      else raise ArgumentError, "unknown select"
      end
    end
  end
end

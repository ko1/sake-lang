module MiniSql
  # A name defined by a WITH clause, as a FROM source.
  class CteBinding
    attr_reader :name, :columns

    # name as written; columns are the cte's columns (the column list applied).
    def initialize(name, columns)
      @name = name
      @columns = columns
    end

    # A source named `label` whose first column is at `offset` of the joined row.
    def source(label, offset)
      raise NotImplementedError, "source"
    end
  end

  # An ordinary cte, or a recursive one seen from outside: a plan that runs wherever it is used.
  class PlannedCte < CteBinding
    def initialize(name, columns, plan)
      super(name, columns)
      @plan = plan
    end

    def source(label, offset)
      DerivedSource.new(label, @plan, offset, columns)
    end
  end

  # A recursive cte seen from its own recursive select: it reads the working set.
  class RecursiveCte < CteBinding
    def initialize(name, columns, working)
      super(name, columns)
      @working = working
    end

    def source(label, offset)
      WorkingSource.new(label, columns, offset, @working)
    end
  end

  # The ctes visible to a select: this binding, then those of the enclosing WITH clauses (parent).
  class CteScope
    def initialize(parent, binding)
      @parent = parent
      @binding = binding
    end

    # The binding called `name` (case-insensitive), the innermost first, or nil.
    def find(name)
      wanted = name.downcase(:ascii)
      scope = self # @type var scope: CteScope?
      while scope
        found = scope.binding
        return found if found.name.downcase(:ascii) == wanted
        scope = scope.parent
      end
      nil
    end

    attr_reader :parent, :binding
  end
end

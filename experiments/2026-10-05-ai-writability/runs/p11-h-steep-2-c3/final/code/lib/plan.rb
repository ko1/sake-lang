module MiniSql
  # A select after name resolution: it knows its result columns and can produce its rows.
  class Plan
    # The result columns (name and affinity), for a plan used as a subquery or a source.
    def columns
      raise NotImplementedError, "columns"
    end

    # The result rows, each as wide as columns.
    def rows
      raise NotImplementedError, "rows"
    end
  end
end

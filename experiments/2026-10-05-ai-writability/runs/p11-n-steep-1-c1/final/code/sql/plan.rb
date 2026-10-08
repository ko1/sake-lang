# frozen_string_literal: true

module Sql
  # A checked query, ready to run with Query.result_rows: a SelectPlan, a CompoundPlan or a
  # RecursivePlan. A plan nested in an expression runs against the row of the query around it
  # (outer_width columns; none for a top-level query).
  class Plan
    def column_count
      raise NotImplementedError
    end

    # The name of each result column (nil if it has none).
    def result_names
      raise NotImplementedError
    end

    # The affinity of each result column (nil: none).
    def result_types
      raise NotImplementedError
    end

    # The expression of each result column, which tells its collation (a compound's are columns
    # standing for the collation they got from its parts: spec 7.4).
    def result_exprs
      raise NotImplementedError
    end

    # The collation of each result column (BINARY for one with none).
    def result_collations
      result_exprs.map(&:collation_or_binary)
    end

    def outer_width
      raise NotImplementedError
    end
  end
end

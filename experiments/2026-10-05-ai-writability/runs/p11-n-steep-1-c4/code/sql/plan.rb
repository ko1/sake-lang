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

    def outer_width
      raise NotImplementedError
    end
  end
end

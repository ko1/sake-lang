# frozen_string_literal: true

require_relative "collation"

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

    # The collation of each result column (nil: none), and whether COLLATE gave it.
    def result_collations
      raise NotImplementedError
    end

    def result_explicit
      raise NotImplementedError
    end

    # The collation the values of each result column compare under (BINARY for none).
    def column_collations
      Collation.defaulted(result_collations)
    end

    def outer_width
      raise NotImplementedError
    end
  end
end

# frozen_string_literal: true

require_relative "evaluator"
require_relative "values"

module Sql
  # LIMIT / OFFSET of a select (1.7).
  module Limits
    module_function

    # The value of a bound LIMIT / OFFSET expression (nil: none, or NULL). It is evaluated with no row
    # of the query in scope (nor of the enclosing one), `row_width` being the width its names resolve in.
    def count(bound, row_width)
      return nil unless bound
      value = Evaluator.evaluate(bound, Array.new(row_width))
      value.nil? ? nil : Values.to_number(value).to_i
    end

    # `rows` without the first `offset` and after `limit` of the rest; a negative limit means no limit.
    def slice(rows, limit, offset)
      rows = rows.drop(offset) if offset && offset > 0
      rows = rows.first(limit) if limit && limit >= 0
      rows
    end
  end
end

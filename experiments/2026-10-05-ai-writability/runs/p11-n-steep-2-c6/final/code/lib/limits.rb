module MiniSql
  # LIMIT and OFFSET (SPEC 1.7).
  module Limits
    # The LIMIT and OFFSET expressions as integers: a nil limit means no limit; the offset is at least 0.
    def self.resolve(limit, offset, environment)
      binder = Binder.new(Sources.new, {}, environment)
      limit_value = integer_of(limit, binder)
      offset_value = integer_of(offset, binder)
      [limit_value && limit_value >= 0 ? limit_value : nil, offset_value && offset_value > 0 ? offset_value : 0]
    end

    # The rows after skipping `offset`, at most `limit` of them.
    def self.slice(rows, limit, offset)
      rest = rows.drop(offset)
      limit ? rest.first(limit) : rest
    end

    def self.integer_of(expr, binder)
      return nil unless expr
      value = Evaluator.evaluate(binder.bind(expr), [])
      case value
      when Integer then value
      when Float then value.to_i
      when String then Value.to_number(value).to_i
      end
    end
  end
end

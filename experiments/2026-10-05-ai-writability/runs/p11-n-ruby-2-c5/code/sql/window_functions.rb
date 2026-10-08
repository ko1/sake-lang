# frozen_string_literal: true

require_relative 'errors'
require_relative 'values'

module SQL
  # The window functions that are not aggregates (SPEC 6.3). Each entry has an argument count range and a
  # block `|partition, i, args, frame|`: `partition` is a WindowPartition, `i` the position of the current
  # row in it, `args` the compiled argument functions (call one with a row), `frame` the WindowFrameRange.
  # The aggregates used with OVER are computed by WindowCalculation. Add new functions here.
  module WindowFunctions
    Function = Struct.new(:arity, :impl)

    REGISTRY = {}

    def self.define(name, arity, &impl)
      REGISTRY[name] = Function.new(arity, impl)
    end

    def self.lookup(name) = REGISTRY[name.downcase]

    # `v` as a positive Integer, or nil.
    def self.positive_integer(v)
      n = Values.to_number(v)
      n = n.to_i if n.is_a?(Float) && n == n.floor
      n if n.is_a?(Integer) && n.positive?
    end

    # --- ranking: they ignore the frame ---------------------------------------------------

    define('row_number', 0..0) { |_part, i, _args, _frame| i + 1 }
    define('rank', 0..0) { |part, i, _args, _frame| part.peer_start(i) + 1 }
    define('dense_rank', 0..0) { |part, i, _args, _frame| part.peer_group(i) + 1 }

    define('percent_rank', 0..0) do |part, i, _args, _frame|
      part.size == 1 ? 0.0 : part.peer_start(i).to_f / (part.size - 1)
    end

    define('cume_dist', 0..0) { |part, i, _args, _frame| (part.peer_end(i) + 1).to_f / part.size }

    # The first `size % n` buckets hold one row more than the others.
    define('ntile', 1..1) do |part, i, args, _frame|
      n = positive_integer(args[0].call(part.rows[i])) or raise SqlError, 'argument of ntile must be a positive integer'
      small, larger = part.size.divmod(n)
      big_rows = larger * (small + 1)
      i < big_rows ? (i / (small + 1)) + 1 : larger + ((i - big_rows) / small) + 1
    end

    # --- other rows of the partition -------------------------------------------------------

    # lag(x [, k [, default]]) is lead with the offset negated.
    { 'lag' => -1, 'lead' => 1 }.each do |name, direction|
      define(name, 1..3) do |part, i, args, _frame|
        row = part.rows[i]
        k = args.size > 1 ? args[1].call(row) : 1
        next nil if k.nil?

        j = i + (direction * Values.to_number(k).to_i)
        if j.between?(0, part.size - 1)
          args[0].call(part.rows[j])
        else
          args.size > 2 ? args[2].call(row) : nil
        end
      end
    end

    # --- the frame -------------------------------------------------------------------------

    define('first_value', 1..1) do |part, i, args, frame|
      first, last = frame.bounds(part, i)
      first > last ? nil : args[0].call(part.rows[first])
    end

    define('last_value', 1..1) do |part, i, args, frame|
      first, last = frame.bounds(part, i)
      first > last ? nil : args[0].call(part.rows[last])
    end

    define('nth_value', 2..2) do |part, i, args, frame|
      n = positive_integer(args[1].call(part.rows[i])) or
        raise SqlError, 'second argument to nth_value must be a positive integer'
      first, last = frame.bounds(part, i)
      first + n - 1 > last ? nil : args[0].call(part.rows[first + n - 1])
    end
  end
end

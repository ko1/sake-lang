# frozen_string_literal: true

require_relative 'aggregates'
require_relative 'compiler'
require_relative 'errors'
require_relative 'ordering'
require_relative 'values'

module SQL
  # One aggregate call, ready to run on the rows of a group (SPEC 3.2). Argument expressions are
  # compiled in `compiler`'s scope, so name errors surface before any row is read.
  class Aggregate
    attr_reader :name

    def initialize(call, compiler)
      @name = call.name.downcase
      unless Aggregates::ARITY.fetch(@name).cover?(call.args.size)
        raise SqlError, "wrong number of arguments to function #{call.name}()"
      end
      if call.distinct && call.args.size != 1
        raise SqlError, 'DISTINCT aggregates must have exactly one argument'
      end

      @distinct = call.distinct
      @star = call.args.first.is_a?(Star)
      @args = @star ? [] : call.args.map { |a| compiler.compile(a).fn }
      @order = call.order_by.map { |t| Ordering::Term.new(t.desc, t.nulls, nil, compiler.compile(t.expr).fn) }
    end

    # min/max: the first row holding the extreme value (a bare column takes its value there, 3.3).
    def extreme_row(rows)
      best = best_row = nil
      sign = @name == 'min' ? -1 : 1
      rows.each do |row|
        v = @args[0].call(row)
        next if v.nil?

        if best.nil? || Values.order_compare(v, best) * sign > 0
          best = v
          best_row = row
        end
      end
      best_row
    end

    def call(rows)
      rows = sorted(rows)
      return rows.size if @star

      pairs = rows.filter_map { |row| (v = @args[0].call(row)) && [v, row] }
      pairs = pairs.uniq { |v, _| Values.group_key(v) } if @distinct
      values = pairs.map(&:first)
      case @name
      when 'count' then values.size
      when 'sum' then sum(values)
      when 'total' then values.empty? ? 0.0 : real_sum(sum_operands(values))
      when 'avg' then values.empty? ? nil : real_sum(sum_operands(values)) / values.size
      when 'min' then values.reduce { |best, v| Values.order_compare(v, best) < 0 ? v : best }
      when 'max' then values.reduce { |best, v| Values.order_compare(v, best) > 0 ? v : best }
      when 'group_concat' then group_concat(pairs)
      end
    end

    private

    def sorted(rows)
      return rows if @order.empty?

      Ordering.sort(rows.map { |r| [@order.map { |t| t.key(r, nil) }, r] }, @order).map(&:last)
    end

    # Each value as the number a sum sees: INTEGER, or a REAL for anything else (3.2 "Sums").
    def sum_operands(values)
      values.map do |v|
        next v unless v.is_a?(String)

        Values.parse_numeric_literal(v) || Values.numeric_prefix(v).to_f
      end
    end

    def sum(values)
      return nil if values.empty?

      nums = sum_operands(values)
      return real_sum(nums) unless nums.all?(Integer)

      total = nums.sum
      raise SqlError, 'integer overflow' unless Values.int64?(total)

      total
    end

    # The REAL sum with compensation (3.2); all-INTEGER input is summed exactly.
    def real_sum(nums)
      first_real = nums.index { |v| !v.is_a?(Integer) }
      return nums.sum.to_f unless first_real

      s = nums[0...first_real].sum.to_f
      c = 0.0
      nums[first_real..].each do |v|
        v = v.to_f
        t = s + v
        c += s.abs > v.abs ? (s - t) + v : (v - t) + s
        s = t
      end
      s + c
    end

    # Values joined by the separator of the row of the later value (default ',').
    def group_concat(pairs)
      return nil if pairs.empty?

      pairs.each_with_index.map do |(v, row), i|
        text = Values.text_form(v)
        next text if i.zero?

        sep = @args.size > 1 ? @args[1].call(row) : ','
        "#{sep.nil? ? '' : Values.text_form(sep)}#{text}"
      end.join
    end
  end
end

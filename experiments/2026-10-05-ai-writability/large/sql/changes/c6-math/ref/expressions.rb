require_relative "values"

# Bound expressions: the syntax tree after name resolution (see Binder), ready to evaluate on a
# Frame. Each knows its affinity (spec 1.9): a column type or nil.
module Expressions
  # What an expression evaluates on: values, the row of its query (the sources' rows side by side,
  # followed in an aggregate query by the values of the aggregate calls); outer, the Frame of the
  # enclosing query's row for a subquery (4.3), else nil; windows, the values of the query's window calls
  # on this row (6.2), set once they are computed.
  Frame = Struct.new(:values, :outer, :windows)
  EMPTY_FRAME = Frame.new([].freeze, nil).freeze

  class Constant
    def initialize(value) = @value = value
    def affinity = nil
    def evaluate(_row) = @value
  end

  class ColumnRef
    def initialize(index, type)
      @index = index
      @type = type
    end

    def affinity = @type
    def evaluate(frame) = frame.values[@index]
  end

  # A name of an enclosing query (4.2): expr is bound in that query and evaluated on its row.
  class Outer
    def initialize(expr) = @expr = expr
    def affinity = @expr.affinity
    def evaluate(frame) = @expr.evaluate(frame.outer)
  end

  # An aggregate call's value in the row an aggregate query evaluates on (Aggregates::Collector); it
  # has no affinity.
  class AggregateRef
    def initialize(index) = @index = index
    def affinity = nil
    def evaluate(frame) = frame.values[@index]
  end

  # A window call's value on the row (Windows::Collector); it has no affinity.
  class WindowRef
    def initialize(index) = @index = index
    def affinity = nil
    def evaluate(frame) = frame.windows[@index]
  end

  class Negate
    def initialize(operand) = @operand = operand
    def affinity = nil

    def evaluate(frame)
      value = @operand.evaluate(frame)
      value.nil? ? nil : -Values.to_number(value)
    end
  end

  # Unary + returns its operand unchanged but drops its affinity.
  class Identity
    def initialize(operand) = @operand = operand
    def affinity = nil
    def evaluate(frame) = @operand.evaluate(frame)
  end

  class Not
    def initialize(operand) = @operand = operand
    def affinity = nil

    def evaluate(frame)
      truth = Values.truth(@operand.evaluate(frame))
      Values.from_truth(truth.nil? ? nil : !truth)
    end
  end

  class And
    def initialize(left, right)
      @left = left
      @right = right
    end

    def affinity = nil

    def evaluate(frame)
      a = Values.truth(@left.evaluate(frame))
      return 0 if a == false
      b = Values.truth(@right.evaluate(frame))
      return 0 if b == false
      Values.from_truth(a.nil? || b.nil? ? nil : true)
    end
  end

  class Or
    def initialize(left, right)
      @left = left
      @right = right
    end

    def affinity = nil

    def evaluate(frame)
      a = Values.truth(@left.evaluate(frame))
      return 1 if a == true
      b = Values.truth(@right.evaluate(frame))
      return 1 if b == true
      Values.from_truth(a.nil? || b.nil? ? nil : false)
    end
  end

  # + - * / % (spec 1.8).
  class Arithmetic
    def initialize(op, left, right)
      @op = op
      @left = left
      @right = right
    end

    def affinity = nil

    def evaluate(frame)
      a = @left.evaluate(frame)
      b = @right.evaluate(frame)
      return nil if a.nil? || b.nil?
      Arithmetic.apply(@op, Values.to_number(a), Values.to_number(b))
    end

    def self.apply(op, a, b)
      if a.is_a?(Integer) && b.is_a?(Integer)
        integer_op(op, a, b)
      elsif op == "%"
        x = a.to_f.truncate
        y = b.to_f.truncate
        y.zero? ? nil : x.remainder(y).to_f
      else
        real_op(op, a.to_f, b.to_f)
      end
    end

    def self.integer_op(op, a, b)
      case op
      when "+" then a + b
      when "-" then a - b
      when "*" then a * b
      when "/" then b.zero? ? nil : a.abs / b.abs * (a.negative? == b.negative? ? 1 : -1)
      when "%" then b.zero? ? nil : a.remainder(b)
      end
    end

    def self.real_op(op, a, b)
      case op
      when "+" then a + b
      when "-" then a - b
      when "*" then a * b
      when "/" then b.zero? ? nil : a / b
      end
    end
  end

  class Concat
    def initialize(left, right)
      @left = left
      @right = right
    end

    def affinity = nil

    def evaluate(frame)
      a = @left.evaluate(frame)
      b = @right.evaluate(frame)
      return nil if a.nil? || b.nil?
      Values.to_text(a) + Values.to_text(b)
    end
  end

  # The conversions before a comparison (spec 1.9): a value is changed by the other operand's affinity.
  module Affinity
    module_function

    def numeric?(affinity) = affinity == "INTEGER" || affinity == "REAL"

    # [a, b] after the rules of 1.9 for operands with affinities affinity_a and affinity_b.
    def apply(a, affinity_a, b, affinity_b)
      if numeric?(affinity_a) && !numeric?(affinity_b)
        b = to_numeric(b)
      elsif numeric?(affinity_b) && !numeric?(affinity_a)
        a = to_numeric(a)
      elsif affinity_a == "TEXT" && affinity_b.nil?
        b = to_text(b)
      elsif affinity_b == "TEXT" && affinity_a.nil?
        a = to_text(a)
      end
      [a, b]
    end

    def to_numeric(value)
      value.is_a?(String) ? (Values.parse_number(value) || value) : value
    end

    def to_text(value)
      value.is_a?(Integer) || value.is_a?(Float) ? Values.to_text(value) : value
    end

    # `a = b` with affinity: true, false, or nil when either is NULL.
    def equal(a, affinity_a, b, affinity_b)
      return nil if a.nil? || b.nil?
      a, b = apply(a, affinity_a, b, affinity_b)
      Values.compare(a, b).zero?
    end
  end

  # = != < <= > >= and IS / IS NOT: operands are converted by affinity, then compared (spec 1.8, 1.9).
  class Comparison
    TESTS = {
      "=" => ->(c) { c.zero? }, "==" => ->(c) { c.zero? },
      "!=" => ->(c) { !c.zero? }, "<>" => ->(c) { !c.zero? },
      "<" => ->(c) { c.negative? }, "<=" => ->(c) { !c.positive? },
      ">" => ->(c) { c.positive? }, ">=" => ->(c) { !c.negative? },
      "IS" => ->(c) { c.zero? }, "IS NOT" => ->(c) { !c.zero? }
    }.freeze

    def initialize(op, left, right)
      @op = op
      @left = left
      @right = right
    end

    def affinity = nil

    def evaluate(frame)
      Values.from_truth(Comparison.test(@op, @left.evaluate(frame), @left.affinity, @right.evaluate(frame), @right.affinity))
    end

    # true, false, or nil (unknown) for `a op b`.
    def self.test(op, a, affinity_a, b, affinity_b)
      null_safe = op.start_with?("IS")
      return nil if !null_safe && (a.nil? || b.nil?)
      a, b = Affinity.apply(a, affinity_a, b, affinity_b)
      TESTS.fetch(op).(Values.compare(a, b))
    end
  end

  # CASE [base] WHEN ... THEN ... [ELSE ...] END (spec 2.3). whens: [[bound condition or value, result]].
  class Case
    def initialize(base, whens, else_expr)
      @base = base
      @whens = whens
      @else_expr = else_expr
    end

    def affinity = nil

    def evaluate(frame)
      chosen = @base ? simple_match(frame) : @whens.find { |condition, _| Values.truth(condition.evaluate(frame)) }
      if chosen then chosen[1].evaluate(frame)
      elsif @else_expr then @else_expr.evaluate(frame)
      end
    end

    private

    def simple_match(frame)
      x = @base.evaluate(frame)
      @whens.find { |value, _| Affinity.equal(x, @base.affinity, value.evaluate(frame), value.affinity) }
    end
  end

  # x [NOT] BETWEEN low AND high: x >= low AND x <= high, x evaluated once (spec 2.3).
  class Between
    def initialize(expr, low, high, negated)
      @expr = expr
      @low = low
      @high = high
      @negated = negated
    end

    def affinity = nil

    def evaluate(frame)
      x = @expr.evaluate(frame)
      above = Comparison.test(">=", x, @expr.affinity, @low.evaluate(frame), @low.affinity)
      below = above == false ? false : Comparison.test("<=", x, @expr.affinity, @high.evaluate(frame), @high.affinity)
      result = (above == false || below == false) ? false : (above.nil? || below.nil? ? nil : true)
      Values.from_truth(@negated && !result.nil? ? !result : result)
    end
  end

  # x [NOT] IN (e1, ...): only x's affinity converts the ei (spec 2.3).
  class In
    def initialize(expr, list, negated)
      @expr = expr
      @list = list
      @negated = negated
    end

    def affinity = nil

    def evaluate(frame)
      values = candidates(frame)
      return Values.from_truth(@negated) if values.empty?
      x = @expr.evaluate(frame)
      result =
        if !x.nil? && values.any? { |v, affinity| equal?(x, v, affinity) } then true
        elsif x.nil? || values.any? { |v, _| v.nil? } then nil
        else false
        end
      Values.from_truth(@negated && !result.nil? ? !result : result)
    end

    private

    # [[value, affinity]] of the values x is compared with.
    def candidates(frame) = @list.map { |e| [e.evaluate(frame), e.affinity] }

    # Rules 1 and 2 of 1.9 applied to ei only: when they would convert x instead, nothing is converted.
    def equal?(x, value, affinity)
      return false if value.nil?
      own = @expr.affinity
      if Affinity.numeric?(own) && !Affinity.numeric?(affinity)
        value = Affinity.to_numeric(value)
      elsif own == "TEXT" && affinity.nil?
        value = Affinity.to_text(value)
      end
      Values.compare(x, value).zero?
    end
  end

  # x [NOT] LIKE p: whole-text match, % and _ wildcards, ASCII case ignored (spec 2.3).
  class Like
    def initialize(expr, pattern, negated)
      @expr = expr
      @pattern = pattern
      @negated = negated
    end

    def affinity = nil

    def evaluate(frame)
      x = @expr.evaluate(frame)
      p = @pattern.evaluate(frame)
      return nil if x.nil? || p.nil?
      matched = Like.match?(Values.to_text(x), Values.to_text(p))
      Values.from_truth(matched != @negated)
    end

    def self.match?(text, pattern)
      source = pattern.tr("A-Z", "a-z").each_char.map do |ch|
        case ch
        when "%" then ".*"
        when "_" then "."
        else Regexp.escape(ch)
        end
      end
      Regexp.new("\\A#{source.join}\\z", Regexp::MULTILINE).match?(text.tr("A-Z", "a-z"))
    end
  end

  # CAST(x AS type) (spec 2.3); it has the affinity of its type.
  class Cast
    def initialize(operand, type)
      @operand = operand
      @type = type
    end

    def affinity = @type

    def evaluate(frame)
      value = @operand.evaluate(frame)
      return nil if value.nil?
      case @type
      when "INTEGER"
        case value
        when Integer then value
        when Float then value.truncate.clamp(Values::INT_MIN, Values::INT_MAX)
        else Values.text_to_integer(value)
        end
      when "REAL" then Values.to_number(value).to_f
      when "TEXT" then Values.to_text(value)
      end
    end
  end

  # x [NOT] IN ( select ) (4.3): the values of the subquery's single column, with its affinity; no
  # rows gives 0 (NOT IN: 1) even when x is NULL. Unlike the list form, the comparisons follow every
  # rule of 1.9 (either side may be converted), as SQLite does: see spec-issues/ref-4.md.
  class InSubquery < In
    def initialize(expr, query, negated)
      super(expr, nil, negated)
      @query = query
    end

    private

    def candidates(frame)
      affinity = @query.affinities[0]
      @query.rows(frame).map { |values| [values[0], affinity] }
    end

    def equal?(x, value, affinity)
      Affinity.equal(x, @expr.affinity, value, affinity) || false
    end
  end

  # ( select ) (4.3): its first row's first value, or NULL; it has its column's affinity.
  class ScalarSubquery
    def initialize(query) = @query = query
    def affinity = @query.affinities[0]
    def evaluate(frame) = @query.rows(frame).first&.first
  end

  class Exists
    def initialize(query) = @query = query
    def affinity = nil
    def evaluate(frame) = @query.rows(frame).empty? ? 0 : 1
  end

  class FunctionCall
    def initialize(function, args)
      @function = function
      @args = args
    end

    def affinity = nil

    def evaluate(frame)
      @function.call(@args.map { |arg| arg.evaluate(frame) })
    end
  end
end

require_relative "values"

# Bound expressions: the syntax tree after name resolution (see Binder), ready to evaluate on a row
# (an array of the table's values). Each knows its affinity (spec 1.9): a column type or nil.
module Expressions
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
    def evaluate(row) = row[@index]
  end

  class Negate
    def initialize(operand) = @operand = operand
    def affinity = nil

    def evaluate(row)
      value = @operand.evaluate(row)
      value.nil? ? nil : -Values.to_number(value)
    end
  end

  # Unary + returns its operand unchanged but drops its affinity.
  class Identity
    def initialize(operand) = @operand = operand
    def affinity = nil
    def evaluate(row) = @operand.evaluate(row)
  end

  class Not
    def initialize(operand) = @operand = operand
    def affinity = nil

    def evaluate(row)
      truth = Values.truth(@operand.evaluate(row))
      Values.from_truth(truth.nil? ? nil : !truth)
    end
  end

  class And
    def initialize(left, right)
      @left = left
      @right = right
    end

    def affinity = nil

    def evaluate(row)
      a = Values.truth(@left.evaluate(row))
      return 0 if a == false
      b = Values.truth(@right.evaluate(row))
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

    def evaluate(row)
      a = Values.truth(@left.evaluate(row))
      return 1 if a == true
      b = Values.truth(@right.evaluate(row))
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

    def evaluate(row)
      a = @left.evaluate(row)
      b = @right.evaluate(row)
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

    def evaluate(row)
      a = @left.evaluate(row)
      b = @right.evaluate(row)
      return nil if a.nil? || b.nil?
      Values.to_text(a) + Values.to_text(b)
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
      @test = TESTS.fetch(op)
      @left = left
      @right = right
    end

    def affinity = nil

    def evaluate(row)
      a = @left.evaluate(row)
      b = @right.evaluate(row)
      null_safe = @op.start_with?("IS")
      return nil if !null_safe && (a.nil? || b.nil?)
      a, b = Comparison.apply_affinity(a, @left.affinity, b, @right.affinity)
      @test.(Values.compare(a, b)) ? 1 : 0
    end

    def self.apply_affinity(a, affinity_a, b, affinity_b)
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

    def self.numeric?(affinity) = affinity == "INTEGER" || affinity == "REAL"

    def self.to_numeric(value)
      value.is_a?(String) ? (Values.parse_number(value) || value) : value
    end

    def self.to_text(value)
      value.is_a?(Integer) || value.is_a?(Float) ? Values.to_text(value) : value
    end
  end

  class FunctionCall
    def initialize(function, args)
      @function = function
      @args = args
    end

    def affinity = nil

    def evaluate(row)
      @function.call(@args.map { |arg| arg.evaluate(row) })
    end
  end
end

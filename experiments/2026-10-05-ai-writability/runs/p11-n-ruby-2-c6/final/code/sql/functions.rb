# frozen_string_literal: true

require_relative 'values'

module SQL
  # Scalar functions (SPEC 1.11, 2.4). Each entry has an argument count range and a lambda that
  # receives the evaluated arguments. Add new functions to REGISTRY.
  module Functions
    Function = Struct.new(:arity, :impl)

    REGISTRY = {}

    def self.define(name, arity, &impl)
      REGISTRY[name] = Function.new(arity, impl)
    end

    # Define a function whose result is NULL when its (single) argument is NULL.
    def self.define_unary(name, &impl)
      define(name, 1..1) { |(x)| x.nil? ? nil : impl.call(x) }
    end

    def self.lookup(name) = REGISTRY[name.downcase]

    define_unary('length') { |x| Values.text_form(x).length }
    define_unary('upper') { |x| Values.text_form(x).upcase(:ascii) }
    define_unary('lower') { |x| Values.text_form(x).downcase(:ascii) }
    define_unary('abs') do |x|
      x.is_a?(String) ? Values.numeric_prefix(x).abs.to_f : x.abs
    end
    define('typeof', 1..1) { |(x)| Values.type_name(x) }
    define('coalesce', 2..) { |args| args.find { |a| !a.nil? } }
    define('ifnull', 2..2) { |(x, y)| x.nil? ? y : x }
    define('nullif', 2..2) do |(x, y)|
      x.nil? || y.nil? || !Values.same?(x, nil, y, nil) ? x : nil
    end

    # Define a function whose result is NULL when any argument is NULL.
    def self.define_strict(name, arity, &impl)
      define(name, arity) { |args| args.any?(&:nil?) ? nil : impl.call(*args) }
    end

    # --- text (2.4) ---------------------------------------------------------------------

    # SQLite's substr on a string (positions count from 1); `len` nil means to the end.
    def self.substr(text, start, len)
      p = start
      q = len
      if p < 0
        p += text.length
        if p < 0
          q += p if q
          p = 0
          q = 0 if q && q < 0
        end
      elsif p > 0
        p -= 1
      elsif q && q > 0
        q -= 1
      end
      if q && q < 0
        q = -q
        p -= q
        if p < 0
          q += p
          p = 0
        end
      end
      return '' if q && q <= 0

      (q ? text[p, q] : text[p..]) || ''
    end

    def self.integer_arg(v) = Values.to_number(v).to_i

    define_strict('substr', 2..3) do |x, start, len = nil|
      substr(Values.text_form(x), integer_arg(start), len && integer_arg(len))
    end

    # trim / ltrim / rtrim: remove any of `chars` (default: spaces) from the chosen ends.
    { 'trim' => %i[left right], 'ltrim' => %i[left], 'rtrim' => %i[right] }.each do |name, ends|
      define_strict(name, 1..2) do |x, chars = ' '|
        set = Values.text_form(chars).chars
        s = Values.text_form(x).chars
        s.shift while ends.include?(:left) && set.include?(s.first)
        s.pop while ends.include?(:right) && set.include?(s.last)
        s.join
      end
    end

    define_strict('replace', 3..3) do |x, from, to|
      from = Values.text_form(from)
      from.empty? ? Values.text_form(x) : Values.text_form(x).gsub(from) { Values.text_form(to) }
    end

    define_strict('instr', 2..2) do |x, y|
      (Values.text_form(x).index(Values.text_form(y)) || -1) + 1
    end

    # --- numbers ------------------------------------------------------------------------

    # Round the 17-digit decimal form of x half away from zero (Rational#round does that).
    define_strict('round', 1..2) do |x, digits = 0|
      n = [integer_arg(digits), 0].max
      exact = Rational(format('%.17g', Values.to_number(x).to_f))
      scale = 10**n
      Rational((exact * scale).round, scale).to_f
    end

    # --- math (7) -----------------------------------------------------------------------

    # An argument as a number (7.1): TEXT only if it is wholly a numeric literal, else nil (NULL).
    def self.math_arg(v) = v.is_a?(String) ? Values.parse_numeric_literal(v) : v

    # Define a math function: every argument goes through math_arg and any NULL gives NULL.
    # The block may itself return nil (NULL).
    def self.define_math(names, arity, &impl)
      Array(names).each do |name|
        define(name, arity) do |args|
          nums = args.map { |a| math_arg(a) }
          nums.any?(&:nil?) ? nil : impl.call(*nums)
        end
      end
    end

    # ceil / floor / trunc: INTEGER stays, REAL gives a whole REAL.
    { %w[ceil ceiling] => :ceil, 'floor' => :floor, 'trunc' => :truncate }.each do |names, op|
      define_math(names, 1..1) do |x|
        x.is_a?(Integer) || !x.finite? ? x : x.public_send(op).to_f
      end
    end

    # C's fmod: truncated remainder with the sign of x.
    define_math('mod', 2..2) do |x, y|
      y = y.to_f
      y.zero? ? nil : x.to_f.remainder(y)
    end

    # Ruby gives a Complex for a negative base with a fractional exponent; C gives NaN (NULL).
    define_math(%w[pow power], 2..2) do |x, y|
      x = x.to_f
      y = y.to_f
      next nil if x.negative? && y.finite? && y != y.floor

      r = x**y
      r.is_a?(Float) && !r.nan? ? r : nil
    end

    define_math('sqrt', 1..1) { |x| x.negative? ? nil : Math.sqrt(x.to_f) }

    define('pi', 0..0) { |_args| Math::PI }

    # max / min with two or more arguments: the first of equal extremes wins.
    { 'max' => 1, 'min' => -1 }.each do |name, sign|
      define_strict(name, 2..) do |*args|
        args.reduce { |best, v| Values.order_compare(v, best) * sign > 0 ? v : best }
      end
    end
  end
end

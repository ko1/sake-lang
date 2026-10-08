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

    # A BLOB's length is in bytes (7.6).
    define_unary('length') { |x| x.is_a?(Blob) ? x.size : Values.text_form(x).length }
    define_unary('upper') { |x| Values.text_form(x).upcase(:ascii) }
    define_unary('lower') { |x| Values.text_form(x).downcase(:ascii) }
    define_unary('abs') do |x|
      x.is_a?(String) || x.is_a?(Blob) ? Values.to_number(x).abs.to_f : x.abs
    end
    define('typeof', 1..1) { |(x)| Values.type_name(x) }
    # hex(NULL) is '' rather than NULL (7.6); other non-BLOBs are hexed through their text form.
    define('hex', 1..1) do |(x)|
      x.nil? ? '' : (x.is_a?(Blob) ? x : Blob.new(Values.text_form(x))).to_hex
    end
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

    # On a BLOB it selects bytes and gives a BLOB (7.6): the same rules with L = the number of bytes.
    define_strict('substr', 2..3) do |x, start, len = nil|
      from = integer_arg(start)
      count = len && integer_arg(len)
      if x.is_a?(Blob)
        Blob.new(substr(x.bytes, from, count))
      else
        substr(Values.text_form(x), from, count)
      end
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
      both_blobs = x.is_a?(Blob) && y.is_a?(Blob)
      hay, needle = both_blobs ? [x.bytes, y.bytes] : [Values.text_form(x), Values.text_form(y)]
      (hay.index(needle) || -1) + 1
    end

    # --- numbers ------------------------------------------------------------------------

    # Round the 17-digit decimal form of x half away from zero (Rational#round does that).
    define_strict('round', 1..2) do |x, digits = 0|
      n = [integer_arg(digits), 0].max
      exact = Rational(format('%.17g', Values.to_number(x).to_f))
      scale = 10**n
      Rational((exact * scale).round, scale).to_f
    end

    # max / min with two or more arguments: the first of equal extremes wins.
    { 'max' => 1, 'min' => -1 }.each do |name, sign|
      define_strict(name, 2..) do |*args|
        args.reduce { |best, v| Values.order_compare(v, best) * sign > 0 ? v : best }
      end
    end
  end
end

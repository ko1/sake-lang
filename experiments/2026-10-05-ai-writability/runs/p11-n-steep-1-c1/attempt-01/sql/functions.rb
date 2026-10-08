# frozen_string_literal: true

require_relative "schema"
require_relative "value"

module Sql
  # Scalar functions. Names are case-insensitive; a max of nil means any number of arguments.
  module Functions
    class Spec
      attr_reader :min, :max

      def initialize(min, max)
        @min = min
        @max = max
      end

      def accepts?(count)
        max = @max
        count >= @min && (max.nil? || count <= max)
      end
    end

    SPECS = {
      "length" => Spec.new(1, 1),
      "upper" => Spec.new(1, 1),
      "lower" => Spec.new(1, 1),
      "abs" => Spec.new(1, 1),
      "typeof" => Spec.new(1, 1),
      "coalesce" => Spec.new(2, nil),
      "ifnull" => Spec.new(2, 2),
      "nullif" => Spec.new(2, 2),
      "substr" => Spec.new(2, 3),
      "trim" => Spec.new(1, 2),
      "ltrim" => Spec.new(1, 2),
      "rtrim" => Spec.new(1, 2),
      "replace" => Spec.new(3, 3),
      "instr" => Spec.new(2, 2),
      "round" => Spec.new(1, 2),
      "max" => Spec.new(2, nil),
      "min" => Spec.new(2, nil)
    }.freeze

    def self.lookup(name)
      SPECS[Names.fold(name)]
    end

    # Calls a function whose name and argument count were already checked by lookup.
    def self.call(name, args)
      function = Names.fold(name)
      case function
      when "typeof" then Value.type_name(args.fetch(0))
      when "coalesce", "ifnull" then args.find { |arg| !arg.nil? }
      when "nullif" then Value.compare(args.fetch(0), args.fetch(1)) == 0 ? nil : args.fetch(0)
      else
        present = args.compact
        present.length == args.length ? non_null(function, present) : nil
      end
    end

    # The functions that return NULL when an argument is NULL, called with none NULL.
    def self.non_null(function, args)
      first = args.fetch(0)
      case function
      when "length" then Value.text_form(first).length
      when "upper" then Value.text_form(first).tr("a-z", "A-Z")
      when "lower" then Value.text_form(first).tr("A-Z", "a-z")
      when "abs" then absolute(first)
      when "substr" then substr(Value.text_form(first), integer(args.fetch(1)), args.length > 2 ? integer(args.fetch(2)) : nil)
      when "trim", "ltrim", "rtrim" then trim(function, Value.text_form(first), args.length > 1 ? Value.text_form(args.fetch(1)) : " ")
      when "replace" then replace(Value.text_form(first), Value.text_form(args.fetch(1)), Value.text_form(args.fetch(2)))
      when "instr" then (Value.text_form(first).index(Value.text_form(args.fetch(1))) || -1) + 1
      when "round" then round(first, args.length > 1 ? integer(args.fetch(1)) : 0)
      when "max" then extreme(args, 1)
      else extreme(args, -1)
      end
    end

    def self.absolute(arg)
      case arg
      when Integer then arg.abs
      when Float then arg.abs
      else Value.to_number(arg).to_f.abs
      end
    end

    def self.integer(arg)
      number = Value.to_number(arg)
      number.is_a?(Float) ? number.truncate : number
    end

    # SQLite's substr (spec 2.4); len is nil when absent (unbounded).
    def self.substr(text, start, len)
      from = start
      count = len
      if from < 0
        from += text.length
        if from < 0
          count += from if count
          from = 0
          count = 0 if count && count < 0
        end
      elsif from > 0
        from -= 1
      elsif count && count > 0
        count -= 1
      end
      if count && count < 0
        count = -count
        from -= count
        if from < 0
          count += from
          from = 0
        end
      end
      return "" if count && count <= 0

      (count ? text[from, count] : text[from..]) || ""
    end

    # which is "trim", "ltrim" or "rtrim"; removes any of the characters in chars.
    def self.trim(which, text, chars)
      first = 0
      last = text.length
      first += 1 while which != "rtrim" && first < last && chars.include?(text[first].to_s)
      last -= 1 while which != "ltrim" && last > first && chars.include?(text[last - 1].to_s)
      text[first...last].to_s
    end

    def self.replace(text, from, to)
      from.empty? ? text : text.gsub(from) { to }
    end

    # round half away from zero on the 17-digit decimal form of x (spec 2.4).
    def self.round(arg, digits)
      x = Value.to_number(arg).to_f
      scale = 10**[digits, 0].max
      scaled = Rational(format("%.17g", x)) * scale
      rounded = (scaled.abs + Rational(1, 2)).floor
      (Rational(x < 0 ? -rounded : rounded, scale)).to_f
    end

    # The largest (direction 1) or smallest (-1) by the order of values, TEXT under the collation;
    # the first of equals.
    def self.extreme(args, direction, collation = :binary)
      best = args.fetch(0)
      args.each { |arg| best = arg if Value.compare(arg, best, collation) == direction }
      best
    end
  end
end

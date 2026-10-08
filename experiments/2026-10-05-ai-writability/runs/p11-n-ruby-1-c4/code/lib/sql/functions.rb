# frozen_string_literal: true

require_relative "errors"
require_relative "identifier"
require_relative "values"

module Sql
  # A scalar function. max is nil for "any number >= min". With null_propagating, a NULL
  # argument gives NULL without calling impl.
  Function = Data.define(:name, :min, :max, :null_propagating, :impl)

  module Functions
    REGISTRY = {}

    def self.define(name, min, max = min, null_propagating: true, &impl)
      REGISTRY[name] = Function.new(name, min, max, null_propagating, impl)
    end

    define("length", 1) { |x| Values.text_form(x).length }
    define("upper", 1) { |x| Values.text_form(x).upcase(:ascii) }
    define("lower", 1) { |x| Values.text_form(x).downcase(:ascii) }
    define("abs", 1) do |x|
      x.is_a?(String) ? Values.numeric_prefix(x).to_f.abs : x.abs
    end
    define("typeof", 1, null_propagating: false) { |x| Values.type_name(x).downcase }
    define("coalesce", 2, nil, null_propagating: false) { |*xs| xs.find { |x| !x.nil? } }
    define("ifnull", 2, null_propagating: false) { |x, y| x.nil? ? y : x }
    define("nullif", 2, null_propagating: false) { |x, y| !x.nil? && !y.nil? && Values.compare(x, y) == 0 ? nil : x }

    define("substr", 2, 3) { |x, start, len = nil| substr(Values.text_form(x), start, len) }

    define("trim", 1, 2) { |x, chars = " "| trim(Values.text_form(x), chars, left: true, right: true) }
    define("ltrim", 1, 2) { |x, chars = " "| trim(Values.text_form(x), chars, left: true, right: false) }
    define("rtrim", 1, 2) { |x, chars = " "| trim(Values.text_form(x), chars, left: false, right: true) }

    define("replace", 3) do |x, from, to|
      text = Values.text_form(x)
      from = Values.text_form(from)
      from.empty? ? text : text.gsub(from) { Values.text_form(to) }
    end

    define("instr", 2) { |x, y| (Values.text_form(x).index(Values.text_form(y)) || -1) + 1 }

    define("round", 1, 2) { |x, digits = 0| round(Values.to_number(x), Values.to_number(digits).to_i) }

    # NULL arguments are skipped, not propagated (C.1).
    define("concat", 1, nil, null_propagating: false) { |*xs| xs.compact.map { |x| Values.text_form(x) }.join }
    define("concat_ws", 2, nil, null_propagating: false) do |sep, *xs|
      sep.nil? ? nil : xs.compact.map { |x| Values.text_form(x) }.join(Values.text_form(sep))
    end
    define("char", 0, nil, null_propagating: false) { |*cs| cs.map { |c| c.to_i.chr(Encoding::UTF_8) }.join }
    define("unicode", 1) { |x| Values.text_form(x).ord unless Values.text_form(x).empty? }
    define("sign", 1) do |x|
      n = x.is_a?(String) ? Values.parse_numeric_literal(x) : x
      n && (n <=> 0)
    end

    define("max", 2, nil) { |*xs| xs.reduce { |best, v| Values.compare(v, best) > 0 ? v : best } }
    define("min", 2, nil) { |*xs| xs.reduce { |best, v| Values.compare(v, best) < 0 ? v : best } }

    # substr per 2.4; start and len (nil: unlimited) are read as integers.
    def self.substr(text, start, len)
      p = Values.to_number(start).to_i
      q = len.nil? ? nil : Values.to_number(len).to_i
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
      return "" if q && q <= 0
      q ? text[p, q] || "" : text[p..] || ""
    end

    def self.trim(text, chars, left:, right:)
      set = Values.text_form(chars).chars
      first = 0
      last = text.length
      first += 1 while left && first < last && set.include?(text[first])
      last -= 1 while right && last > first && set.include?(text[last - 1])
      text[first...last]
    end

    # Rounds the 17-digit decimal form of x, halves away from zero, to n >= 0 digits (2.4).
    def self.round(x, digits)
      digits = 0 if digits < 0
      exact = Rational(format("%.17g", x.to_f))
      scale = 10**digits
      units = (exact.abs * scale + Rational(1, 2)).floor
      Rational(exact.negative? ? -units : units, scale).to_f
    end

    # Finds the function for a call as written, checking the argument count.
    def self.lookup(name, argc)
      fn = REGISTRY[Sql.fold(name)] or raise SqlError, "no such function: #{name}"
      if argc < fn.min || (fn.max && argc > fn.max)
        raise SqlError, "wrong number of arguments to function #{name}()"
      end
      fn
    end

    def self.call(fn, args)
      return nil if fn.null_propagating && args.any?(&:nil?)
      fn.impl.call(*args)
    end
  end
end

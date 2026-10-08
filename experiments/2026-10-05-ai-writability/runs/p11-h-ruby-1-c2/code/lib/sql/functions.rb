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

    define("length", 1) { |x| x.is_a?(Blob) ? x.data.bytesize : Values.text_form(x).length }
    define("upper", 1) { |x| Values.text_form(x).upcase(:ascii) }
    define("lower", 1) { |x| Values.text_form(x).downcase(:ascii) }
    define("abs", 1) do |x|
      x.is_a?(String) || x.is_a?(Blob) ? Values.to_number(x).to_f.abs : x.abs
    end
    define("typeof", 1, null_propagating: false) { |x| Values.type_name(x).downcase }
    define("coalesce", 2, nil, null_propagating: false) { |*xs| xs.find { |x| !x.nil? } }
    define("ifnull", 2, null_propagating: false) { |x, y| x.nil? ? y : x }
    define("nullif", 2, null_propagating: false) { |x, y| !x.nil? && !y.nil? && Values.compare(x, y) == 0 ? nil : x }

    define("substr", 2, 3) do |x, start, len = nil|
      if x.is_a?(Blob) # works on the bytes and gives a BLOB (7.6)
        Values.blob(substr(x.data, start, len))
      else
        substr(Values.text_form(x), start, len)
      end
    end

    define("trim", 1, 2) { |x, chars = " "| trim(Values.text_form(x), chars, left: true, right: true) }
    define("ltrim", 1, 2) { |x, chars = " "| trim(Values.text_form(x), chars, left: true, right: false) }
    define("rtrim", 1, 2) { |x, chars = " "| trim(Values.text_form(x), chars, left: false, right: true) }

    define("replace", 3) do |x, from, to|
      text = Values.text_form(x)
      from = Values.text_form(from)
      from.empty? ? text : text.gsub(from) { Values.text_form(to) }
    end

    define("instr", 2) do |x, y|
      # two BLOBs: by bytes; otherwise on text forms (7.6)
      haystack, needle = x.is_a?(Blob) && y.is_a?(Blob) ? [x.data, y.data] : [Values.text_form(x), Values.text_form(y)]
      (haystack.index(needle) || -1) + 1
    end

    # Unlike the others, NULL is not passed through: hex(NULL) is ''.
    define("hex", 1, null_propagating: false) do |x|
      x.nil? ? "" : Values.hex_digits(x.is_a?(Blob) ? x.data : Values.text_form(x))
    end

    define("round", 1, 2) { |x, digits = 0| round(Values.to_number(x), Values.to_number(digits).to_i) }

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

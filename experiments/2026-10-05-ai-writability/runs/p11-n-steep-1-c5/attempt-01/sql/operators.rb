# frozen_string_literal: true

require_relative "value"

module Sql
  # The SQL operators on already-evaluated values (nil is NULL).
  module Operators
    def self.arithmetic(op, left, right)
      return nil if left.nil? || right.nil?

      x = Value.to_number(left)
      y = Value.to_number(right)
      if x.is_a?(Integer) && y.is_a?(Integer)
        integer_arithmetic(op, x, y)
      else
        real_arithmetic(op, x.to_f, y.to_f)
      end
    end

    def self.integer_arithmetic(op, x, y)
      case op
      when "+" then x + y
      when "-" then x - y
      when "*" then x * y
      when "/"
        return nil if y.zero?

        quotient = x.abs / y.abs
        (x < 0) == (y < 0) ? quotient : -quotient
      else
        y.zero? ? nil : x.remainder(y)
      end
    end

    def self.real_arithmetic(op, x, y)
      case op
      when "+" then x + y
      when "-" then x - y
      when "*" then x * y
      when "/" then y == 0.0 ? nil : x / y
      else
        divisor = y.truncate
        divisor.zero? ? nil : x.truncate.remainder(divisor).to_f
      end
    end

    def self.negate(value)
      return nil if value.nil?

      -Value.to_number(value)
    end

    def self.concat(left, right)
      return nil if left.nil? || right.nil?

      Value.text_form(left) + Value.text_form(right)
    end

    # = != < <= > >= with affinity; NULL if either side is NULL.
    def self.comparison(op, left, left_aff, right, right_aff)
      return nil if left.nil? || right.nil?

      l, r = Value.coerce_for_comparison(left, left_aff, right, right_aff)
      c = Value.compare(l, r)
      outcome =
        case op
        when "=" then c == 0
        when "!=" then c != 0
        when "<" then c < 0
        when "<=" then c <= 0
        when ">" then c > 0
        else c >= 0
        end
      outcome ? 1 : 0
    end

    # IS: equality that is never NULL.
    def self.same?(left, left_aff, right, right_aff)
      return left.nil? && right.nil? if left.nil? || right.nil?

      l, r = Value.coerce_for_comparison(left, left_aff, right, right_aff)
      Value.compare(l, r) == 0
    end

    # Whether text matches a LIKE pattern: % any run, _ any one character, ASCII case ignored.
    # With an escape character, it makes the next pattern character ordinary; a trailing one
    # matches nothing.
    def self.like?(text, pattern, escape = nil)
      chars = pattern.each_char.to_a
      parts = [] #: Array[String]
      i = 0
      while i < chars.size
        c = chars.fetch(i)
        if c == escape
          return false if i + 1 >= chars.size

          parts << Regexp.escape(chars.fetch(i + 1).tr("A-Z", "a-z"))
          i += 2
          next
        end
        parts <<
          case c
          when "%" then ".*"
          when "_" then "."
          else Regexp.escape(c.tr("A-Z", "a-z"))
          end
        i += 1
      end
      Regexp.new("\\A#{parts.join}\\z", Regexp::MULTILINE).match?(text.tr("A-Z", "a-z"))
    end

    # Whether text matches a GLOB pattern: case-sensitive; * any run, ? any one character,
    # [set] / [^set] one character with ranges.
    def self.glob?(text, pattern)
      regexp = glob_regexp(pattern)
      !regexp.nil? && regexp.match?(text)
    end

    # The regexp for a GLOB pattern, or nil when it can match nothing (an unclosed '[').
    def self.glob_regexp(pattern)
      chars = pattern.each_char.to_a
      parts = [] #: Array[String]
      i = 0
      while i < chars.size
        c = chars.fetch(i)
        if c == "["
          close = glob_class_end(chars, i)
          return nil if close.nil?

          parts << glob_class(chars[(i + 1)...close].to_a)
          i = close + 1
          next
        end
        parts <<
          case c
          when "*" then ".*"
          when "?" then "."
          else Regexp.escape(c)
          end
        i += 1
      end
      Regexp.new("\\A#{parts.join}\\z", Regexp::MULTILINE)
    end

    # The index of the ']' closing the class opened at open, or nil. A ']' right after '[' or
    # '[^' is a member.
    def self.glob_class_end(chars, open)
      first = open + 1
      first += 1 if chars[first] == "^"
      close = chars.index("]", first + 1)
      close
    end

    # The regexp text for one class; body is what lies between '[' and the closing ']'.
    def self.glob_class(body)
      negated = body.first == "^"
      members = negated ? body.drop(1) : body
      ranges = [] #: Array[String]
      i = 0
      while i < members.size
        low = members.fetch(i)
        if i + 2 < members.size && members.fetch(i + 1) == "-"
          high = members.fetch(i + 2)
          ranges << "#{glob_code(low)}-#{glob_code(high)}" if low.ord <= high.ord
          i += 3
        else
          ranges << glob_code(low)
          i += 1
        end
      end
      if ranges.empty?
        negated ? "." : "(?!)"
      else
        "[#{negated ? '^' : ''}#{ranges.join}]"
      end
    end

    def self.glob_code(char)
      "\\u{#{char.ord.to_s(16)}}"
    end
  end
end

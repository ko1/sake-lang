module MiniSql
  # The scalar functions (SPEC 1.11, 2.4).
  module Functions
    MANY = 255

    # name => accepted numbers of arguments.
    ARITY = {
      "length" => (1..1), "upper" => (1..1), "lower" => (1..1), "abs" => (1..1), "typeof" => (1..1),
      "coalesce" => (2..MANY), "ifnull" => (2..2), "nullif" => (2..2),
      "substr" => (2..3), "trim" => (1..2), "ltrim" => (1..2), "rtrim" => (1..2),
      "replace" => (3..3), "instr" => (2..2), "round" => (1..2), "max" => (2..MANY), "min" => (2..MANY),
      "ceil" => (1..1), "ceiling" => (1..1), "floor" => (1..1), "trunc" => (1..1), "mod" => (2..2),
      "pow" => (2..2), "power" => (2..2), "sqrt" => (1..1), "pi" => (0..0)
    }.freeze

    # Whether name (any case) takes this many arguments: :ok, :unknown or :arity.
    def self.check(name, count)
      range = ARITY[name.downcase(:ascii)]
      return :unknown unless range
      range.cover?(count) ? :ok : :arity
    end

    # name is lower case and its argument count has been checked.
    def self.call(name, args)
      first = args.fetch(0, nil)
      case name
      when "coalesce", "ifnull" then args.find { |arg| !arg.nil? }
      when "nullif" then nullif(first, args.fetch(1, nil))
      when "typeof" then Value.type_name(first).downcase
      when "pi" then Math::PI
      else args.any?(&:nil?) ? nil : non_null(name, args)
      end
    end

    # Functions that give NULL when any argument is NULL; args has no NULL.
    def self.non_null(name, args)
      value = args.fetch(0, nil)
      second = args.fetch(1, nil)
      case name
      when "substr" then substr(Value.text_form(value), second, args.fetch(2, nil))
      when "trim", "ltrim", "rtrim" then trim(name, Value.text_form(value), second)
      when "replace" then replace(Value.text_form(value), Value.text_form(second), Value.text_form(args.fetch(2, nil)))
      when "instr" then (Value.text_form(value).index(Value.text_form(second)) || -1) + 1
      when "round" then round(value, second)
      when "max" then extreme(args, 1)
      when "min" then extreme(args, -1)
      when "ceil", "ceiling", "floor", "trunc", "mod", "pow", "power", "sqrt" then math(name, args)
      else unary(name, value)
      end
    end

    # Functions of one non-NULL argument.
    def self.unary(name, value)
      case name
      when "length" then Value.text_form(value).length
      when "upper" then Value.text_form(value).upcase(:ascii)
      when "lower" then Value.text_form(value).downcase(:ascii)
      else absolute(value)
      end
    end

    def self.absolute(value)
      case value
      when Integer then value.abs
      when Float then value.abs
      else Value.to_number(value).to_f.abs
      end
    end

    # A non-NULL argument of a math function as a number (SPEC 7.1), or nil: only a whole numeric literal counts.
    def self.math_number(value)
      case value
      when Integer then value
      when Float then value
      when String then Value.parse_number(value)
      end
    end

    # ceil, floor, trunc, mod, pow, power and sqrt (SPEC 7.2); args has no NULL.
    def self.math(name, args)
      numbers = args.filter_map { |arg| math_number(arg) }
      return nil unless numbers.length == args.length
      x = numbers.fetch(0)
      case name
      when "mod" then remainder(x.to_f, numbers.fetch(1).to_f)
      when "pow", "power" then power(x.to_f, numbers.fetch(1).to_f)
      when "sqrt" then x < 0 ? nil : Math.sqrt(x.to_f)
      else x.is_a?(Integer) ? x : whole(name, x)
      end
    end

    # ceil / floor / trunc of a REAL, as a REAL.
    def self.whole(name, real)
      case name
      when "ceil", "ceiling" then real.ceil.to_f
      when "floor" then real.floor.to_f
      else real.truncate.to_f
      end
    end

    # fmod: the sign is the dividend's; nil for a zero divisor.
    def self.remainder(dividend, divisor)
      return nil if divisor == 0.0
      rest = dividend % divisor
      rest -= divisor if rest != 0.0 && (rest < 0.0) != (dividend < 0.0)
      rest
    end

    # pow: nil when the result is not a real number.
    def self.power(base, exponent)
      result = base**exponent
      result.is_a?(Float) && !result.nan? ? result : nil
    end

    # NULL if the two are equal (no affinity), else the first.
    def self.nullif(first, second)
      return first if first.nil? || second.nil?
      Value.compare(first, second).zero? ? nil : first
    end

    # substr(text, start[, len]) with SQLite's position rules (SPEC 2.4).
    def self.substr(text, start, length)
      from = Value.to_integer(start)
      count = length ? Value.to_integer(length) : nil
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
      text[from, count || text.length].to_s
    end

    # trim / ltrim / rtrim: strip the characters of `chars` (spaces by default) from the ends.
    def self.trim(name, text, chars)
      set = chars ? Value.text_form(chars) : " "
      first = 0
      last = text.length
      first += 1 while name != "rtrim" && first < last && set.include?(text[first].to_s)
      last -= 1 while name != "ltrim" && last > first && set.include?(text[last - 1].to_s)
      text[first, last - first].to_s
    end

    def self.replace(text, from, replacement)
      from.empty? ? text : text.gsub(from) { replacement }
    end

    # round(x[, digits]): half away from zero on x's 17-digit decimal form; a REAL.
    def self.round(value, digits)
      number = Value.to_number(value)
      places = digits ? [Value.to_integer(digits), 0].max : 0
      return number.to_f if number.is_a?(Integer) || !number.finite?
      scale = 10**places
      exact = Rational(format("%.17g", number))
      Rational((exact * scale).round, scale).to_f
    end

    # The largest (direction 1) or smallest (-1) argument in the order of values; the first of equals.
    def self.extreme(args, direction)
      best = args.fetch(0, nil)
      args.each { |arg| best = arg if Value.compare(arg, best) * direction > 0 }
      best
    end
  end
end

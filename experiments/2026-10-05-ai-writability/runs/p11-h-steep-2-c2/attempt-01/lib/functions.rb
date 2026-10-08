module MiniSql
  # The scalar functions (SPEC 1.11, 2.4).
  module Functions
    MANY = 255

    # name => accepted numbers of arguments.
    ARITY = {
      "length" => (1..1), "upper" => (1..1), "lower" => (1..1), "abs" => (1..1), "typeof" => (1..1),
      "coalesce" => (2..MANY), "ifnull" => (2..2), "nullif" => (2..2),
      "substr" => (2..3), "trim" => (1..2), "ltrim" => (1..2), "rtrim" => (1..2),
      "replace" => (3..3), "instr" => (2..2), "hex" => (1..1), "round" => (1..2), "max" => (2..MANY), "min" => (2..MANY)
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
      when "hex" then hex(first)
      else args.any?(&:nil?) ? nil : non_null(name, args)
      end
    end

    # Functions that give NULL when any argument is NULL; args has no NULL.
    def self.non_null(name, args)
      value = args.fetch(0, nil)
      second = args.fetch(1, nil)
      case name
      when "substr" then substr_of(value, second, args.fetch(2, nil))
      when "trim", "ltrim", "rtrim" then trim(name, Value.text_form(value), second)
      when "replace" then replace(Value.text_form(value), Value.text_form(second), Value.text_form(args.fetch(2, nil)))
      when "instr" then instr(value, second)
      when "round" then round(value, second)
      when "max" then extreme(args, 1)
      when "min" then extreme(args, -1)
      else unary(name, value)
      end
    end

    # Functions of one non-NULL argument.
    def self.unary(name, value)
      case name
      when "length" then value.is_a?(Blob) ? value.bytes.bytesize : Value.text_form(value).length
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

    # NULL if the two are equal (no affinity), else the first.
    def self.nullif(first, second)
      return first if first.nil? || second.nil?
      Value.compare(first, second).zero? ? nil : first
    end

    # hex(x): two uppercase hexadecimal digits per byte of a BLOB, else of the text form (NULL gives '').
    def self.hex(value)
      return value.hex if value.is_a?(Blob)
      Value.text_form(value).each_byte.map { |byte| format("%02X", byte) }.join
    end

    # substr on a BLOB selects bytes and gives a BLOB; otherwise it works on the text form.
    def self.substr_of(value, start, length)
      return Blob.new(substr(value.bytes, start, length)) if value.is_a?(Blob)
      substr(Value.text_form(value), start, length)
    end

    # instr(x, y): 1-based position of the first y in x, 0 if none; bytes when both are BLOBs, else text forms.
    def self.instr(value, needle)
      found =
        if value.is_a?(Blob) && needle.is_a?(Blob)
          value.bytes.index(needle.bytes)
        else
          Value.text_form(value).index(Value.text_form(needle))
        end
      (found || -1) + 1
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

module MiniSql
  # The scalar functions (SPEC 1.11).
  module Functions
    MANY = 255

    # name => accepted numbers of arguments.
    ARITY = {
      "length" => (1..1), "upper" => (1..1), "lower" => (1..1), "abs" => (1..1), "typeof" => (1..1),
      "coalesce" => (2..MANY), "ifnull" => (2..2), "nullif" => (2..2)
    }.freeze

    # Whether name (any case) takes this many arguments: :ok, :unknown or :arity.
    def self.check(name, count)
      range = ARITY[name.downcase(:ascii)]
      return :unknown unless range
      range.cover?(count) ? :ok : :arity
    end

    def self.call(name, args)
      first = args.fetch(0, nil)
      case name
      when "coalesce", "ifnull" then args.find { |arg| !arg.nil? }
      when "nullif" then nullif(first, args.fetch(1, nil))
      when "typeof" then Value.type_name(first).downcase
      else first.nil? ? nil : unary(name, first)
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

    # NULL if the two are equal (no affinity), else the first.
    def self.nullif(first, second)
      return first if first.nil? || second.nil?
      Value.compare(first, second).zero? ? nil : first
    end
  end
end

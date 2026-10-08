require_relative "values"

# The scalar functions (spec 1.11), looked up case-insensitively.
module Functions
  # arity: the allowed argument counts; null_in_null_out: a NULL argument gives NULL without calling.
  Function = Struct.new(:arity, :null_in_null_out, :body) do
    def call(args)
      return nil if null_in_null_out && args.any?(&:nil?)
      body.(*args)
    end
  end

  def self.ascii_case(value, from, to)
    Values.to_text(value).tr(from, to)
  end

  def self.abs(value)
    case value
    when Integer, Float then value.abs
    else Values.to_number(value).to_f.abs
    end
  end

  TABLE = {
    "length" => Function.new(1..1, true, ->(x) { Values.to_text(x).length }),
    "upper" => Function.new(1..1, true, ->(x) { ascii_case(x, "a-z", "A-Z") }),
    "lower" => Function.new(1..1, true, ->(x) { ascii_case(x, "A-Z", "a-z") }),
    "abs" => Function.new(1..1, true, ->(x) { abs(x) }),
    "typeof" => Function.new(1..1, false, ->(x) { Values.type_name(x) }),
    "coalesce" => Function.new(2.., false, ->(*xs) { xs.find { |x| !x.nil? } }),
    "ifnull" => Function.new(2..2, false, ->(x, y) { x.nil? ? y : x }),
    "nullif" => Function.new(2..2, false, ->(x, y) { !x.nil? && !y.nil? && Values.compare(x, y).zero? ? nil : x })
  }.freeze

  # The function for a call written as `name(n arguments)`; raises SqlError for an unknown name or count.
  def self.lookup(name, argument_count)
    function = TABLE[name.downcase] or raise SqlError, "no such function: #{name}"
    unless function.arity.include?(argument_count)
      raise SqlError, "wrong number of arguments to function #{name}()"
    end
    function
  end
end

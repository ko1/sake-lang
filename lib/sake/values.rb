# frozen_string_literal: true

module Sake
  # Literal `[a, b]`: length and positional types are fixed; elements may be replaced by the same type.
  # Ruby Arrays are used as Sake Arrays (`Array[a, b]`).
  class Tuple
    attr_reader :elems

    def initialize(elems)
      @elems = elems
    end

    # Structural, so that Tuples work as Hash keys and Set elements.
    def ==(other) = other.is_a?(Tuple) && @elems == other.elems
    alias eql? ==
    def hash = [Tuple, @elems].hash
  end

  # `T[...]`: an Array whose element type is declared; checked on every write.
  class TypedArray < ::Array
    attr_reader :elem_type

    def initialize(elem_type, elems)
      super(elems)
      @elem_type = elem_type
    end
  end

  # exception: made by Exception.new (or built in); its first field is message and it can be raised.
  StructType = Struct.new(:name, :fields, :exception)

  # The type of a Record: its set of (field, type) pairs, sorted by field and interned.
  Shape = Struct.new(:fields, :types) do
    def name = "{#{fields.zip(types).map { |f, t| "#{f}: #{t}" }.join(", ")}}"
    def display = "{#{fields.zip(types).map { |f, t| "#{f}: #{Values.display_type(t)}" }.join(", ")}}"
  end

  # `{x: 1, y: 2}`: the shape is fixed at creation; values may be replaced by ones of the same type.
  class RecordValue
    SHAPES = {}
    attr_reader :shape, :values

    def self.build(pairs)
      sorted = pairs.sort_by(&:first)
      fields = sorted.map(&:first)
      types = sorted.map { Values.type_of(_1[1]) }
      new(SHAPES[[fields, types]] ||= Shape.new(fields.freeze, types.freeze), sorted.map(&:last))
    end

    def initialize(shape, values)
      @shape = shape
      @values = values
    end

    def field?(f) = @shape.fields.include?(f)
    def [](f) = @values[@shape.fields.index(f)]

    def ==(other) = other.is_a?(RecordValue) && @shape.equal?(other.shape) && @values == other.values
    alias eql? ==
    def hash = [RecordValue, @shape.fields, @values].hash
  end

  # An instance of a Struct.new type; fields are mutable.
  class StructValue
    attr_reader :type, :values

    def initialize(type, values)
      @type = type
      @values = values
    end
  end

  module Values
    module_function

    def type_of(v)
      case v
      when Integer then "Integer"
      when Float then "Float"
      when String then "String"
      when true, false then "Boolean"
      when nil then "Nil"
      when Tuple then "Tuple"
      when Array then "Array"
      when StructValue then v.type.name
      when RecordValue then v.shape.name
      when Symbol then "Symbol"
      when Rational then "Rational"
      when Complex then "Complex"
      when Time then "Time"
      when Hash then "Hash"
      when Set then "Set"
      when Range then "Range"
      when Regexp then "Regexp"
      when MatchData then "MatchData"
      else raise "BUG: not a Sake value: #{v.inspect}"
      end
    end

    # For messages: nil/true/false are shown as themselves, other values by type name.
    def describe(v)
      case v
      when nil, true, false then v.inspect
      when RecordValue then v.shape.display
      else type_of(v)
      end
    end

    # For messages about table rows keyed by internal type names.
    def display_type(t) = { "Nil" => "nil", "Boolean" => "true|false" }.fetch(t, t)

    def truthy?(v) = !(v.nil? || v == false)

    # Hash keys and Set elements: values compared by content. A Struct, Array, Hash or Set is not one,
    # because equality of those types is undecided (protocols).
    def key_value?(v)
      case v
      when Integer, Float, Rational, Complex, String, Symbol, Time, true, false, nil then true
      when Tuple then v.elems.all? { key_value?(_1) }
      when RecordValue then v.values.all? { key_value?(_1) }
      else false
      end
    end

    # Keys are copied on insertion, so a later write to a Tuple or Record cannot change a stored key.
    def key_copy(v)
      case v
      when Tuple then Tuple.new(v.elems.map { key_copy(_1) })
      when RecordValue then RecordValue.new(v.shape, v.values.map { key_copy(_1) })
      when String then v.frozen? ? v : v.dup.freeze
      else v
      end
    end

    # Same output as Ruby's #inspect so that expected outputs match Ruby versions of a task.
    def inspect(v)
      case v
      when Tuple then "[#{v.elems.map { inspect(_1) }.join(", ")}]"
      when Array then "[#{v.map { inspect(_1) }.join(", ")}]"
      when StructValue
        fs = v.type.fields.zip(v.values).map { |f, x| "#{f}=#{inspect(x)}" }
        if v.type.exception
          "#<#{v.type.name}: #{to_s(v.values[0])}#{fs.drop(1).map { " #{_1}" }.join}>"
        else
          "#<struct #{v.type.name} #{fs.join(", ")}>"
        end
      when RecordValue then "{#{v.shape.fields.zip(v.values).map { |f, x| "#{f}: #{inspect(x)}" }.join(", ")}}"
      when Hash
        "{#{v.map { |k, x| k.is_a?(Symbol) && k.inspect.match?(/\A:\w+[?!]?\z/) ? "#{k}: #{inspect(x)}" : "#{inspect(k)} => #{inspect(x)}" }.join(", ")}}"
      when Set then "Set[#{v.map { inspect(_1) }.join(", ")}]"
      when Range then "#{v.begin.nil? ? "" : inspect(v.begin)}#{v.exclude_end? ? "..." : ".."}#{v.end.nil? ? "" : inspect(v.end)}"
      else v.inspect
      end
    end

    def to_s(v)
      case v
      when String then v
      when nil then ""
      when Tuple, Array, StructValue, RecordValue, Hash, Set then inspect(v)
      when Range then inspect(v)
      else v.to_s
      end
    end

    # Lines written by Ruby's `puts v`.
    def puts_lines(v)
      case v
      when Array then v.empty? ? [""] : v.flat_map { puts_lines(_1) }
      when Tuple then v.elems.empty? ? [""] : v.elems.flat_map { puts_lines(_1) }
      else [to_s(v)]
      end
    end
  end
end

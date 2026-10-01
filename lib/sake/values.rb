# frozen_string_literal: true

module Sake
  # Literal `[a, b]`. Ruby Arrays are used as Sake Arrays (`Array[a, b]`).
  class Tuple
    attr_reader :elems

    def initialize(elems)
      @elems = elems.freeze
    end
  end

  # `T[...]`: an Array whose element type is declared; checked on every write.
  class TypedArray < ::Array
    attr_reader :elem_type

    def initialize(elem_type, elems)
      super(elems)
      @elem_type = elem_type
    end
  end

  StructType = Struct.new(:name, :fields)

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

    # Same output as Ruby's #inspect so that expected outputs match Ruby versions of a task.
    def inspect(v)
      case v
      when Tuple then "[#{v.elems.map { inspect(_1) }.join(", ")}]"
      when Array then "[#{v.map { inspect(_1) }.join(", ")}]"
      when StructValue
        fs = v.type.fields.zip(v.values).map { |f, x| "#{f}=#{inspect(x)}" }
        "#<struct #{v.type.name} #{fs.join(", ")}>"
      when RecordValue then "{#{v.shape.fields.zip(v.values).map { |f, x| "#{f}: #{inspect(x)}" }.join(", ")}}"
      else v.inspect
      end
    end

    def to_s(v)
      case v
      when String then v
      when nil then ""
      when Tuple, Array, StructValue, RecordValue then inspect(v)
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

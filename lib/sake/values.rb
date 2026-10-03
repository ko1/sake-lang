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
    # Dictionary order, as Ruby's Array (nil when some pair of elements cannot be compared).
    def <=>(other) = other.is_a?(Tuple) ? @elems <=> other.elems : nil
    def to_s = Values.inspect(self) # for Ruby methods such as join and format
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
  # field_types: field => type name fixed by a default value. getters / setters: field => Builtin, used by
  # `@x` inside the type's functions whether or not the field is public.
  # own_equality: the type defines == (or Comparable with <=>); its values cannot be Hash keys or Set elements.
  # A Sake thread: Thread.new's value, around Ruby's Thread.
  ThreadValue = Struct.new(:thread)

  StructType = Struct.new(:name, :fields, :exception, :field_types, :getters, :setters, :own_equality)

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
    def to_s = Values.inspect(self)
    alias eql? ==
    def hash = [RecordValue, @shape.fields, @values].hash
  end

  # An instance of a Struct.new type; fields are mutable.
  class StructValue
    attr_reader :type, :values

    def to_s = Values.to_s(self) # for Ruby methods such as format

    # Used by Ruby methods (include?, sort, ...): the type's own == and <=> when the interpreter runs.
    def ==(other)
      hook = Thread.current[:sake_struct_ops]
      hook ? hook.call(:==, self, other) : other.is_a?(StructValue) && other.type.equal?(type) && other.values == values
    end

    def <=>(other) = Thread.current[:sake_struct_ops]&.call(:<=>, self, other)

    # As Hash keys and Set elements: by type and fields, like the default == (types with their own
    # equality are refused as keys, see Values.key_value?).
    def eql?(other) = other.is_a?(StructValue) && other.type.equal?(@type) && @values.eql?(other.values)
    def hash = [StructValue, @type.name, @values].hash

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
      when ThreadValue then "Thread"
      else
        # Ruby's own objects for the concurrency and network operations (stdlib_net.rb).
        name = { "Thread::Queue" => "Queue", "Thread::Mutex" => "Mutex", "TCPServer" => "TCPServer", "TCPSocket" => "Socket" }[v.class.name]
        name or raise "BUG: not a Sake value: #{v.inspect}"
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
      when ::Array, ::Set then v.all? { key_value?(_1) }
      when ::Hash then v.all? { |k, x| key_value?(k) && key_value?(x) }
      when StructValue then !v.type.own_equality && v.values.all? { key_value?(_1) }
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
      if v.is_a?(StructValue) && (h = hooks) && (s = h.call(:inspect, v))
        return s
      end
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
      when ThreadValue, ::Thread::Queue, ::Thread::Mutex then "#<#{type_of(v)}>"
      else v.class.name.to_s.match?(/\A(TCPServer|TCPSocket)\z/) ? "#<#{type_of(v)}>" : v.inspect
      end
    end

    # A running interpreter installs hooks so that a type's own to_s / inspect are used.
    def hooks = Thread.current[:sake_show_hooks]

    def to_s(v)
      if v.is_a?(StructValue) && (h = hooks) && (s = h.call(:to_s, v))
        return s
      end
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

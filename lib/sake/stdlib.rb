# frozen_string_literal: true

module Sake
  # Built-in operations. Names follow Ruby's core API (DESIGN.md: API is Ruby's).
  # Operations whose Ruby version returns nil on a miss (first, find, min, ...) are left out
  # until the nil design is settled.
  module Stdlib
    NUM = %w[Integer Float].freeze
    ARITH = %i[+ - * / %].freeze
    COMPARE = %i[< <= > >=].freeze

    module_function

    def install(reg, out)
      install_binary_ops(reg)
      install_kernel(reg, out)
      install_integer(reg)
      install_float(reg)
      install_string(reg)
      install_array(reg)
      install_tuple(reg)
      install_math(reg)
      install_index(reg)
      %w[Integer Float String Tuple].each { install_typed_array(reg, _1) }
    end

    def int_pow(a, b)
      if b.negative?
        base = a.negative? ? "(#{a}r)" : "#{a}r"
        raise Fail.new("ArgumentError", "Integer ** negative Integer (#{a} ** #{b}) is an error; for a Rational, write #{base} ** #{b}")
      end
      a**b
    end

    def int_div(op, a, b)
      raise Fail.new("ZeroDivisionError", "divided by 0") if b.zero?
      a.public_send(op, b)
    end

    def install_binary_ops(reg)
      NUM.product(NUM) do |t1, t2|
        (ARITH + COMPARE + %i[== !=]).each do |op|
          if t1 == "Integer" && t2 == "Integer" && %i[/ %].include?(op)
            reg.define_binary(op, t1, t2) { |a, b| int_div(op, a, b) }
          else
            reg.define_binary(op, t1, t2) { |a, b| a.public_send(op, b) }
          end
        end
        if t1 == "Integer" && t2 == "Integer"
          reg.define_binary(:**, t1, t2) { |a, b| int_pow(a, b) }
        else
          reg.define_binary(:**, t1, t2) { |a, b| a**b }
        end
      end
      reg.define_binary(:+, "String", "String") { |a, b| a + b }
      reg.define_binary(:*, "String", "Integer") { |a, b| a * b }
      (COMPARE + %i[== !=]).each { |op| reg.define_binary(op, "String", "String") { |a, b| a.public_send(op, b) } }
      %w[Boolean Nil].each do |t|
        %i[== !=].each { |op| reg.define_binary(op, t, t) { |a, b| a.public_send(op, b) } }
      end
      %w[Integer Float String Boolean Tuple Array].each { define_nil_equality(reg, _1) }
      %w[Integer Float Rational Complex].each { |t| %i[-@ +@].each { |op| reg.define_unary(op, t) { |a| a.public_send(op) } } }
      reg.define_unary(:~, "Integer") { |a| ~a }
      # Collections compare by their contents; Tuple and Array also in dictionary order.
      %w[Tuple Array Set Hash].each { |t| %i[== !=].each { |op| reg.define_binary(op, t, t) { |a, b| a.public_send(op, b) } } }
      %w[Tuple Array].each do |t|
        reg.define_binary(:<=>, t, t) { |a, b| a <=> b }
        COMPARE.each do |op|
          reg.define_binary(op, t, t) do |a, b|
            c = a <=> b
            raise Fail.new("ArgumentError", "comparison of #{t} with #{t} failed (elements that cannot be compared)") if c.nil?
            c.public_send(op, 0)
          end
        end
      end
    end

    # `x == nil` / `x != nil` for any type T (Ruby semantics: false / true unless x is nil).
    def define_nil_equality(reg, type)
      %i[== !=].each do |op|
        reg.define_binary(op, type, "Nil") { |a, b| a.public_send(op, b) }
        reg.define_binary(op, "Nil", type) { |a, b| a.public_send(op, b) }
      end
    end

    # `Integer.+(a, b)` etc.: the operator with both operands fixed to the type.
    # Kept for the callers; the operator functions are defined from the table by install_operator_functions.
    def install_typed_ops(_reg, _type, _ops) = nil

    # `T.op(a, b)` for each built-in type T: the rows of the table whose left operand is T.
    def install_operator_functions(reg)
      reg.binary_ops.each do |op, rows|
        rows.keys.map(&:first).uniq.each do |type|
          next unless reg.namespace?(type) && reg.lookup(type, op).nil?
          right = rows.keys.select { _1[0] == type }.map(&:last)
          reg.define(type, op, [type, "Any"]) do |a, b|
            impl = rows[[type, Values.type_of(b)]]
            unless impl
              raise Fail.new("TypeError", "no implementation for (#{type}, #{Values.describe(b)}); " \
                                          "defined for (#{type}, #{right.map { Values.display_type(_1) }.join("|")})")
            end
            impl.(a, b)
          end
        end
      end
    end

    def install_kernel(reg, out)
      reg.define("Kernel", :puts, [], rest: "Any") do |*args|
        lines = args.empty? ? [""] : args.flat_map { Values.puts_lines(_1) }
        lines.each { |l| out.write(l.end_with?("\n") ? l : "#{l}\n") }
        nil
      end
      reg.define("Kernel", :print, [], rest: "Any") do |*args|
        args.each { out.write(Values.to_s(_1)) }
        nil
      end
      reg.define("Kernel", :p, ["Any"]) do |v|
        out.write("#{Values.inspect(v)}\n")
        v
      end
    end

    def install_integer(reg)
      install_typed_ops(reg, "Integer", ARITH + COMPARE + %i[== != **])
      reg.define("Integer", :to_s, ["Integer"], &:to_s)
      reg.define("Integer", :to_f, ["Integer"], &:to_f)
      reg.define("Integer", :abs, ["Integer"], &:abs)
      reg.define("Integer", :succ, ["Integer"], &:succ)
      reg.define("Integer", :pred, ["Integer"], &:pred)
      reg.define("Integer", :even?, ["Integer"], &:even?)
      reg.define("Integer", :odd?, ["Integer"], &:odd?)
      reg.define("Integer", :zero?, ["Integer"], &:zero?)
      reg.define("Integer", :times, ["Integer"], block: :required) { |n, &b| n.times { b.(_1) }; n }
      reg.define("Integer", :upto, %w[Integer Integer], block: :required) { |a, z, &b| a.upto(z) { b.(_1) }; a }
      reg.define("Integer", :downto, %w[Integer Integer], block: :required) { |a, z, &b| a.downto(z) { b.(_1) }; a }
    end

    def install_float(reg)
      install_typed_ops(reg, "Float", ARITH + COMPARE + %i[== != **])
      reg.define("Float", :to_s, ["Float"], &:to_s)
      reg.define("Float", :to_i, ["Float"]) { |f| float_to_i(f, &:to_i) }
      reg.define("Float", :floor, ["Float"]) { |f| float_to_i(f, &:floor) }
      reg.define("Float", :ceil, ["Float"]) { |f| float_to_i(f, &:ceil) }
      reg.define("Float", :round, ["Float"], optional: ["Integer"]) do |f, digits = nil|
        digits ? f.round(digits).to_f : float_to_i(f, &:round)
      end
      reg.define("Float", :abs, ["Float"], &:abs)
      reg.define("Float", :nan?, ["Float"], &:nan?)
    end

    def float_to_i(f)
      raise Fail.new("FloatDomainError", f.to_s) unless f.finite?
      yield f
    end

    def install_string(reg)
      install_typed_ops(reg, "String", %i[+ == != < <= > >=])
      reg.define("String", :*, %w[String Integer]) do |s, n|
        raise Fail.new("ArgumentError", "negative argument #{n}") if n.negative?
        s * n
      end
      %i[length size upcase downcase capitalize swapcase reverse strip lstrip rstrip chomp
         empty? to_i to_f chars lines].each do |m|
        reg.define("String", m, ["String"], &m)
      end
      reg.define("String", :to_s, ["String"]) { _1 }
      %i[include? start_with? end_with?].each do |m|
        reg.define("String", m, %w[String String]) { |s, t| s.public_send(m, t) }
      end
      reg.define("String", :split, ["String"], optional: ["String"]) { |s, sep = nil| s.split(sep) }
      reg.define("String", :sub, %w[String String String]) { |s, a, b| s.sub(a, b) }
      reg.define("String", :gsub, %w[String String String]) { |s, a, b| s.gsub(a, b) }
      reg.define("String", :count, %w[String String]) { |s, t| s.count(t) }
      reg.define("String", :index, %w[String String]) { |s, t| s.index(t) }
      reg.define("String", :each_char, ["String"], block: :required) { |s, &b| s.each_char { b.(_1) }; s }
      reg.define("String", :ljust, %w[String Integer], optional: ["String"]) { |s, n, pad = " "| s.ljust(n, pad) }
      reg.define("String", :rjust, %w[String Integer], optional: ["String"]) { |s, n, pad = " "| s.rjust(n, pad) }
    end

    def install_array(reg)
      reg.define("Array", CTOR, [], rest: "Any") { |*xs| xs }
      reg.define("Array", :length, ["Array"], &:length)
      reg.define("Array", :size, ["Array"], &:size)
      reg.define("Array", :empty?, ["Array"], &:empty?)
      reg.define("Array", :push, ["Array"], rest: "Any") { |a, *xs| a.push(*check_elems(a, xs)) }
      reg.define("Array", :append, ["Array"], rest: "Any") { |a, *xs| a.push(*check_elems(a, xs)) }
      reg.define("Array", :concat, %w[Array Array]) { |a, b| a.concat(check_elems(a, b)) }
      reg.define("Array", :include?, %w[Array Any]) { |a, x| a.include?(x) }
      reg.define("Array", :join, ["Array"], optional: ["String"]) { |a, sep = ""| a.map { Values.to_s(_1) }.join(sep) }
      reg.define("Array", :reverse, ["Array"], &:reverse)
      reg.define("Array", :sum, ["Array"]) do |a|
        a.each { |x| raise Fail.new("TypeError", "Array.sum: element must be Integer or Float, got #{Values.describe(x)}") unless NUM.include?(Values.type_of(x)) }
        a.sum
      end
      reg.define("Array", :sort, ["Array"]) { |a| sort_checked(a) { a.sort } }
      reg.define("Array", :sort_by, ["Array"], block: :required) { |a, &b| ks = []; sort_checked(a, ks) { a.sort_by { ks << b.(_1); ks[-1] } } }
      reg.define("Array", :take, %w[Array Integer]) { |a, n| nonneg(n) && a.take(n) }
      reg.define("Array", :drop, %w[Array Integer]) { |a, n| nonneg(n) && a.drop(n) }
      reg.define("Array", :each, ["Array"], block: :required) { |a, &b| a.each { b.(_1) }; a }
      reg.define("Array", :each_with_index, ["Array"], block: :required) { |a, &b| a.each_with_index { b.(_1, _2) }; a }
      reg.define("Array", :map, ["Array"], block: :required) { |a, &b| a.map { b.(_1) } }
      %i[select filter reject].each do |m|
        reg.define("Array", m, ["Array"], block: :required) { |a, &b| a.public_send(m) { Values.truthy?(b.(_1)) } }
      end
      %i[any? all? none?].each do |m|
        reg.define("Array", m, ["Array"], block: :required) { |a, &b| a.public_send(m) { Values.truthy?(b.(_1)) } }
      end
      # These return nil on a miss, as in Ruby.
      reg.define("Array", :at, %w[Array Integer]) { |a, i| a[i] }
      reg.define("Array", :fetch, %w[Array Integer]) do |a, i|
        a.fetch(i)
      rescue IndexError => e
        raise Fail.new("IndexError", e.message)
      end
      reg.define("Array", :first, ["Array"], &:first)
      reg.define("Array", :last, ["Array"], &:last)
      reg.define("Array", :pop, ["Array"], &:pop)
      reg.define("Array", :shift, ["Array"], &:shift)
      reg.define("Array", :unshift, ["Array"], rest: "Any") { |a, *xs| a.unshift(*check_elems(a, xs)) }
      reg.define("Array", :min, ["Array"]) { |a| sort_checked(a) { a.min } }
      reg.define("Array", :max, ["Array"]) { |a| sort_checked(a) { a.max } }
      reg.define("Array", :min_by, ["Array"], block: :required) { |a, &b| ks = []; sort_checked(a, ks) { a.min_by { ks << b.(_1); ks[-1] } } }
      reg.define("Array", :max_by, ["Array"], block: :required) { |a, &b| ks = []; sort_checked(a, ks) { a.max_by { ks << b.(_1); ks[-1] } } }
      %i[find detect].each do |m|
        reg.define("Array", m, ["Array"], block: :required) { |a, &b| a.find { Values.truthy?(b.(_1)) } }
      end
      reg.define("Array", :index, %w[Array Any]) { |a, x| a.index(x) }
      reg.define("Array", :find_index, ["Array"], block: :required) { |a, &b| a.find_index { Values.truthy?(b.(_1)) } }
      reg.define("Array", :count, ["Array"], block: :required) { |a, &b| a.count { Values.truthy?(b.(_1)) } }
      %i[reduce inject].each do |m|
        reg.define("Array", m, %w[Array Any], block: :required) { |a, init, &b| a.reduce(init) { |acc, x| b.(acc, x) } }
      end
    end

    def check_elems(a, xs)
      return xs unless a.is_a?(TypedArray)
      xs.each do |x|
        t = Values.type_of(x)
        raise Fail.new("TypeError", "#{a.elem_type}[] element must be #{a.elem_type}, got #{Values.describe(x)}") if t != a.elem_type
      end
      xs
    end

    # `T[...]` for a type T (built-in or Struct). `Array[...]` stays the untyped constructor.
    def install_typed_array(reg, type, struct: false)
      reg.define(type, CTOR, [], rest: "Any") do |*xs|
        xs.each_with_index do |x, i|
          next if Values.type_of(x) == type
          hint = struct ? " (to create one #{type}, write #{type}.new(...))" : ""
          raise Fail.new("TypeError", "element #{i + 1} must be #{type}, got #{Values.describe(x)}#{hint}")
        end
        TypedArray.new(type, xs)
      end
    end

    def nonneg(n)
      raise Fail.new("ArgumentError", "negative size #{n}") if n.negative?
      true
    end

    # keys: for the *_by forms, the block results seen so far (those are what is compared).
    def sort_checked(a, keys = nil)
      yield
    rescue ArgumentError, NoMethodError
      vals = keys || a
      types = vals.map { Values.describe(_1) }.uniq
      hint = types.include?("Tuple") ? " (Tuples compare element by element; some elements cannot be compared)" : ""
      raise Fail.new("ArgumentError", "cannot compare #{keys ? "block results" : "elements"} of types #{types.join(", ")}#{hint}")
    end

    INDEX_ROWS = "(Array, Integer), (Array, Range), (String, Integer), (String, Range), (Tuple, Integer), " \
                 "(Hash, any key), (MatchData, Integer), (MatchData, String)"
    INDEX_SET_ROWS = "(Array, Integer), (Tuple, Integer), (Hash, any key)"

    # `x[k]` and `x[k] = v` call these. A miss gives nil as in Ruby, except that a Tuple's length is part
    # of its type, so reading or writing outside it is an IndexError.
    # `T.[](x, k)` / `T.[]=(x, k, v)` for the built-in Indexable types.
    def install_index(reg)
      %w[Array Hash String Tuple MatchData].each do |t|
        reg.add_namespace(t)
        reg.define(t, :[], [t, "Any"]) { |x, k| index_get(x, k) }
        reg.define(t, :[]=, [t, "Any", "Any"]) { |x, k, v| index_set(x, k, v) } unless %w[String MatchData].include?(t)
      end
    end

    def index_get(x, k)
      case [x, k]
      in [Array | String, Integer | Range] then x[k]
      in [Tuple, Integer] then x.elems[tuple_pos(x, k)]
      in [Hash, _] then x[k]
      in [MatchData, Integer | String | Symbol]
        begin
          x[k]
        rescue ::IndexError => e
          raise Fail.new("IndexError", e.message)
        end
      else raise Fail.new("TypeError", "no implementation for (#{Values.describe(x)}, #{Values.describe(k)}); defined for #{INDEX_ROWS}")
      end
    end

    def index_set(x, k, v)
      case [x, k]
      in [TypedArray, Integer] if k > x.size
        raise Fail.new("IndexError", "index #{k} is past the end of #{x.elem_type}[] (length #{x.size}); the gap would be nil")
      in [Array, Integer]
        check_elems(x, [v])
        begin
          x[k] = v
        rescue IndexError => e
          raise Fail.new("IndexError", e.message)
        end
      in [Hash, _] then x[key!(k)] = v
      in [Tuple, Integer]
        i = tuple_pos(x, k)
        want = Values.type_of(x.elems[i])
        raise Fail.new("TypeError", "Tuple position #{k} holds #{Values.display_type(want)}, got #{Values.describe(v)}") if Values.type_of(v) != want
        x.elems[i] = v
      else raise Fail.new("TypeError", "no implementation for (#{Values.describe(x)}, #{Values.describe(k)}); defined for #{INDEX_SET_ROWS}")
      end
    end

    def tuple_pos(t, k)
      n = t.elems.size
      raise Fail.new("IndexError", "index #{k} is outside a Tuple of length #{n}") unless (-n...n).cover?(k)
      k.negative? ? n + k : k
    end

    def install_tuple(reg)
      reg.define("Tuple", :length, ["Tuple"]) { _1.elems.length }
      reg.define("Tuple", :size, ["Tuple"]) { _1.elems.size }
    end

    def install_math(reg)
      %i[sqrt cbrt sin cos tan atan exp log log2 log10].each do |m|
        reg.define("Math", m, [NUM]) do |x|
          Math.public_send(m, x)
        rescue Math::DomainError => e
          raise Fail.new("Math::DomainError", e.message)
        end
      end
      reg.define("Math", :atan2, [NUM, NUM]) { |y, x| Math.atan2(y, x) }
      reg.define("Math", :hypot, [NUM, NUM]) { |x, y| Math.hypot(x, y) }
    end
  end
end

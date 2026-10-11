# frozen_string_literal: true

module Sake
  # `Hash[k => v, ...]` passes its pairs as one argument of this type.
  HashPairs = Struct.new(:pairs)

  # Ruby's Symbol, Range, Hash, Set, Regexp/MatchData, I/O, and more of Integer/Float/String/Array.
  module Stdlib
    module_function

    def flatten_all(xs) = xs.flat_map { |x| x.is_a?(Array) ? flatten_all(x) : (x.is_a?(Tuple) ? flatten_all(x.elems) : [x]) }

    def install_ext(reg, out, input)
      install_ext_body(reg, out, input)
      Operators::MODULES.each { reg.add_namespace(_1) }
      install_operator_functions(reg)
    end

    def install_ext_body(reg, out, input)
      install_table(reg)
      install_numeric_tower(reg)
      install_time(reg)
      install_symbol(reg)
      install_range(reg)
      install_hash(reg)
      install_set(reg)
      install_regexp(reg)
      install_io(reg, input)
      install_concurrency(reg)
      install_net(reg)
      install_more_kernel(reg)
      install_more_numeric(reg)
      install_more_string(reg)
      install_more_array(reg)
      install_text(reg, out)
      install_streams(reg, out, input)
      install_core_more(reg)
      install_ext_binary_ops(reg)
    end

    def key!(x)
      return Values.key_copy(x) if Values.key_value?(x)
      if x.is_a?(StructValue) && x.type.own_equality
        raise Fail.new("TypeError", "#{x.type.name} cannot be a Hash key or Set element: it defines its own equality (== or <=>)")
      end
      raise Fail.new("TypeError", "#{Values.describe(x)} cannot be a Hash key or Set element " \
                                  "(it contains a value that cannot: a Regexp, a Range, or a Struct value with its own equality)")
    end

    def pair(k, v) = Tuple.new([k, v])

    # Runs Ruby and names the Sake kind of its ArgumentError / RangeError / IndexError (the vague ones);
    # a more specific Ruby error (KeyError, FloatDomainError, TypeError, ...) keeps its class (Interpreter#ruby_run_error).
    def ruby_error(kind)
      yield
    rescue ::RangeError, ::ArgumentError, ::IndexError => e
      raise e if (e.is_a?(::KeyError) || e.is_a?(::FloatDomainError)) && e.class.name != kind
      raise Fail.new(kind, e.message)
    end

    # dig: each key steps into an Array (an Integer index), a Tuple (an Integer position), or a Hash; a miss, or
    # nil on the way, gives nil (Ruby's dig, with Tuples added).
    def dig_into(x, keys)
      keys.each do |k|
        x = case x
            when nil then return nil
            when Array, Tuple
              raise Fail.new("TypeError", "an index into #{Values.describe(x)} must be Integer, got #{Values.describe(k)}") unless k.is_a?(Integer)
              x.is_a?(Tuple) ? x.elems[k] : x[k]
            when Hash then x[k]
            else raise Fail.new("TypeError", "#{Values.describe(x)} cannot be dug into (not an Array, a Tuple, or a Hash)")
            end
      end
      x
    end

    # format's values: a Tuple spreads into the arguments, a Record is the Hash of `%<name>s` (as Ruby's).
    def format_arg(x)
      case x
      when Tuple then x.elems
      when RecordValue then x.shape.fields.zip(x.values).to_h { |k, v| [k.to_sym, v] }
      else x
      end
    end

    def install_ext_binary_ops(reg)
      (REAL.product(REAL) + [%w[String String], %w[Time Time]]).each do |t1, t2|
        reg.define_binary(:<=>, t1, t2) { |a, b| a <=> b }
      end
      %i[& | ^ << >>].each { |op| reg.define_binary(op, "Integer", "Integer") { |a, b| a.public_send(op, b) } }
      %i[| & -].each { |op| reg.define_binary(op, "Set", "Set") { |a, b| a.public_send(op, b) } }
      %w[Symbol IO Regexp Range Thread Mutex Queue Socket TCPServer].each { |t| %i[== !=].each { |op| reg.define_binary(op, t, t) { |a, b| a.public_send(op, b) } } }
      reg.define_binary(:=~, "String", "Regexp") { |s, r| s =~ r }
      reg.define_binary(:=~, "Regexp", "String") { |r, s| r =~ s }
      reg.define_binary(:!~, "String", "Regexp") { |s, r| s !~ r }
      %w[Integer Float String Symbol Tuple Record Hash Nil Boolean].each do |t|
        reg.define_binary(:%, "String", t) do |f, x|
          ruby_error("ArgumentError") { f % format_arg(x) }
        end
      end
    end

    REAL = %w[Integer Float Rational].freeze
    NUMERIC = (REAL + ["Complex"]).freeze

    def num_op(op, a, b)
      op == :** ? real_pow(a, b) : a.public_send(op, b)
    rescue ::ZeroDivisionError
      raise Fail.new("ZeroDivisionError", "divided by 0")
    end

    # Rational and Complex join the table. `Integer ** negative Integer` stays an error (ko1's decision), so
    # that the result type does not depend on a value; `2r ** -1` gives a Rational.
    def install_numeric_tower(reg)
      NUMERIC.product(NUMERIC) do |t1, t2|
        next if t1 != "Rational" && t1 != "Complex" && t2 != "Rational" && t2 != "Complex"
        %i[+ - * / **].each { |op| reg.define_binary(op, t1, t2) { |a, b| num_op(op, a, b) } }
        %i[== !=].each { |op| reg.define_binary(op, t1, t2) { |a, b| a.public_send(op, b) } }
        next if t1 == "Complex" || t2 == "Complex"
        %i[% < <= > >=].each { |op| reg.define_binary(op, t1, t2) { |a, b| num_op(op, a, b) } }
      end
      install_typed_ops(reg, "Rational", %i[+ - * / % ** < <= > >= == !=])
      install_typed_ops(reg, "Complex", %i[+ - * / ** == !=])
      reg.define("Kernel", :Rational, [%w[Integer Float Rational String]], optional: [%w[Integer Rational]]) do |a, b = 1|
        Rational(a, b)
      rescue ::ZeroDivisionError
        raise Fail.new("ZeroDivisionError", "divided by 0")
      rescue ::ArgumentError => e
        raise Fail.new("ArgumentError", e.message)
      end
      reg.define("Kernel", :Complex, [REAL], optional: [REAL]) { |a, b = 0| Complex(a, b) }
      reg.define("Integer", :to_r, ["Integer"], &:to_r)
      reg.define("Float", :to_r, ["Float"]) { |f| float_to_i(f, &:to_r) }
      reg.define("Float", :rationalize, ["Float"]) { |f| float_to_i(f, &:rationalize) }
      reg.define("Integer", :fdiv, %w[Integer Integer]) { |a, b| a.fdiv(b) }
      %i[numerator denominator to_i floor ceil round truncate].each { |m| reg.define("Rational", m, ["Rational"], &m) }
      reg.define("Rational", :to_f, ["Rational"], &:to_f)
      reg.define("Rational", :to_s, ["Rational"], &:to_s)
      reg.define("Rational", :abs, ["Rational"], &:abs)
      reg.define("Rational", :zero?, ["Rational"], &:zero?)
      %i[real imaginary arg conjugate].each { |m| reg.define("Complex", m, ["Complex"], &m) }
      reg.define("Complex", :abs, ["Complex"]) { |c| c.abs.then { _1.is_a?(Rational) ? _1.to_f : _1 } } # Complex(3r, 0).abs is (3/1) in Ruby
      reg.define("Complex", :to_s, ["Complex"], &:to_s)
      reg.define("Complex", :rectangular, ["Complex"]) { |c| Tuple.new(c.rectangular) }
      reg.define("Complex", :polar, ["Complex"]) { |c| Tuple.new(c.polar.map { _1.is_a?(Rational) ? _1.to_f : _1 }) } # as abs: a Rational magnitude is a Float
      %w[sqrt cbrt sin cos tan atan exp log log2 log10].each { |m| reg.lookup("Math", m).params[0] = REAL }
      reg.lookup("Array", "sum").impl = lambda do |a, &b|
        xs = b ? a.map { b.(_1) } : a
        xs.each { |x| raise Fail.new("TypeError", "element must be a number, got #{Values.describe(x)}") unless NUMERIC.include?(Values.type_of(x)) }
        xs.sum
      end
    end

    TIME_FIELDS = %i[year month day hour min sec wday yday].freeze

    def install_time(reg)
      # A zone is a fixed UTC offset ("+09:00", "Z", "UTC", "A".."Z", or seconds), as Ruby's `in:`.
      zone = { "in" => %w[String Integer] }
      reg.define("Time", :now, [], keywords: zone) { |**kw| ruby_error("ArgumentError") { Time.now(**kw) } }
      reg.define("Time", :at, [REAL + ["Time"]], keywords: zone) { |s, **kw| ruby_error("ArgumentError") { Time.at(s, **kw) } }
      reg.define("Time", :new, ["Integer"], optional: [*%w[Integer Integer Integer Integer], REAL, %w[String Integer]], keywords: zone) do |*xs, **kw|
        ruby_error("ArgumentError") { Time.new(*xs, **kw) }
      end
      TIME_FIELDS.each { |m| reg.define("Time", m, ["Time"], &m) }
      reg.define("Time", :to_i, ["Time"], &:to_i)
      reg.define("Time", :to_f, ["Time"], &:to_f)
      reg.define("Time", :to_s, ["Time"], &:to_s)
      reg.define("Time", :utc, ["Time"]) { _1.dup.utc }
      reg.define("Time", :strftime, %w[Time String]) { |t, f| t.strftime(f) }
      %w[Integer Float Rational].each do |n|
        reg.define_binary(:+, "Time", n) { |t, s| t + s }
        reg.define_binary(:-, "Time", n) { |t, s| t - s }
      end
      reg.define_binary(:-, "Time", "Time") { |a, b| a - b }
      %i[< <= > >= == !=].each { |op| reg.define_binary(op, "Time", "Time") { |a, b| a.public_send(op, b) } }
    end

    def install_symbol(reg)
      reg.define("Symbol", :to_s, ["Symbol"], &:to_s)
      reg.define("Symbol", :to_sym, ["Symbol"]) { _1 }
      reg.define("Symbol", :length, ["Symbol"], &:length)
      reg.define("Symbol", :size, ["Symbol"], &:size)
      reg.define("String", :to_sym, ["String"], &:to_sym)
      reg.define("String", :intern, ["String"], &:to_sym)
    end

    # Iteration goes through Integer or String ranges (String#succ), as Ruby's.
    def int_range!(r, string: true)
      return if r.begin.is_a?(Integer) || (string && r.begin.is_a?(String))
      raise Fail.new("TypeError", "this operation needs a Range that starts with an Integer#{string ? " or a String" : ""}, got #{Values.inspect(r)}")
    end

    def finite!(r)
      raise Fail.new("RangeError", "cannot do this on an endless Range #{Values.inspect(r)}") if r.end.nil?
    end

    def install_range(reg)
      reg.define("Range", :each, ["Range"], block: :required) { |r, &b| int_range!(r); r.each { b.(_1) }; r }
      reg.define("Range", :each_with_index, ["Range"], block: :required) { |r, &b| int_range!(r); r.each_with_index { b.(_1, _2) }; r }
      reg.define("Range", :step, %w[Range Integer], block: :required) { |r, n, &b| int_range!(r, string: false); r.step(n) { b.(_1) }; r }
      reg.define("Range", :to_a, ["Range"]) { |r| int_range!(r); finite!(r); r.to_a }
      reg.define("Range", :map, ["Range"], block: :required) { |r, &b| int_range!(r); finite!(r); r.map { b.(_1) } }
      %i[select filter reject].each do |m|
        reg.define("Range", m, ["Range"], block: :required) { |r, &b| int_range!(r); finite!(r); r.public_send(m) { Values.truthy?(b.(_1)) } }
      end
      %i[any? all? none?].each do |m|
        reg.define("Range", m, ["Range"], block: :required) { |r, &b| int_range!(r); finite!(r); r.public_send(m) { Values.truthy?(b.(_1)) } }
      end
      %i[find detect].each do |m|
        reg.define("Range", m, ["Range"], block: :required) { |r, &b| int_range!(r); r.find { Values.truthy?(b.(_1)) } }
      end
      %i[reduce inject].each do |m|
        reg.define("Range", m, %w[Range Any], block: :required) { |r, init, &b| int_range!(r); finite!(r); r.reduce(init) { |acc, x| b.(acc, x) } }
      end
      reg.define("Range", :sum, ["Range"], optional: [NUMERIC], block: :optional) { |r, init = 0, &b| int_range!(r, string: false); finite!(r); b ? r.sum(init) { b.(_1) } : r.sum(init) }
      reg.define("Range", :size, ["Range"]) { |r| int_range!(r, string: false); finite!(r); r.size }
      reg.define("Range", :count, ["Range"], block: :optional) do |r, &b|
        int_range!(r)
        finite!(r)
        b ? r.count { Values.truthy?(b.(_1)) } : r.count
      end
      # include? / member? walk a String Range ("a".."z" does not include "mm"); cover? compares with the ends.
      %i[include? cover? member?].each do |m|
        reg.define("Range", m, %w[Range Any]) { |r, x| ruby_error("ArgumentError") { m == :cover? ? r.cover?(x) : r.include?(x) } }
      end
      reg.define("Range", :first, ["Range"], optional: ["Integer"]) { |r, n = nil| ruby_error("RangeError") { n ? r.first(n) : r.first } }
      reg.define("Range", :last, ["Range"], optional: ["Integer"]) { |r, n = nil| finite!(r); ruby_error("RangeError") { n ? r.to_a.last(n) : r.last } }
      reg.define("Range", :min, ["Range"]) { |r| finite!(r); r.min }
      reg.define("Range", :max, ["Range"]) { |r| finite!(r); r.max }
      reg.define("Range", :begin, ["Range"], &:begin)
      reg.define("Range", :end, ["Range"], &:end)
      reg.define("Range", :exclude_end?, ["Range"], &:exclude_end?)
    end

    def install_hash(reg)
      reg.define("Hash", CTOR, [], rest: "Any") do |*args|
        h = {}
        args.each { |hp| hp.pairs.each { |k, v| h[key!(k)] = v } }
        h
      end
      reg.define("Hash", :new, [], optional: ["Any"]) { |default = nil| Hash.new(default) }
      reg.define("Hash", :length, ["Hash"], &:length)
      reg.define("Hash", :size, ["Hash"], &:size)
      reg.define("Hash", :empty?, ["Hash"], &:empty?)
      %i[key? has_key? include? member?].each { |m| reg.define("Hash", m, %w[Hash Any]) { |h, k| h.key?(k) } }
      %i[value? has_value?].each { |m| reg.define("Hash", m, %w[Hash Any]) { |h, v| h.value?(v) } }
      reg.define("Hash", :fetch, %w[Hash Any], optional: ["Any"]) do |h, k, *default|
        h.fetch(k, *default)
      rescue ::KeyError
        raise Fail.new("KeyError", "key not found: #{Values.inspect(k)}")
      end
      reg.define("Hash", :dig, %w[Hash Any], rest: "Any") { |h, k, *ks| dig_into(h, [k, *ks]) }
      reg.define("Hash", :store, %w[Hash Any Any]) { |h, k, v| h[key!(k)] = v }
      reg.define("Hash", :delete, %w[Hash Any]) { |h, k| h.delete(k) }
      reg.define("Hash", :keys, ["Hash"], &:keys)
      reg.define("Hash", :values, ["Hash"], &:values)
      reg.define("Hash", :to_a, ["Hash"]) { |h| h.map { |k, v| pair(k, v) } }
      reg.define("Hash", :key, %w[Hash Any]) { |h, v| h.key(v) }
      reg.define("Hash", :invert, ["Hash"]) { |h| h.each_with_object({}) { |(k, v), r| r[key!(v)] = k } }
      reg.define("Hash", :merge, %w[Hash Hash]) { |a, b| a.merge(b) }
      reg.define("Hash", :clear, ["Hash"], &:clear)
      %i[each each_pair].each do |m|
        reg.define("Hash", m, ["Hash"], block: :required) { |h, &b| h.each { |k, v| b.(pair(k, v)) }; h }
      end
      reg.define("Hash", :each_key, ["Hash"], block: :required) { |h, &b| h.each_key { b.(_1) }; h }
      reg.define("Hash", :each_value, ["Hash"], block: :required) { |h, &b| h.each_value { b.(_1) }; h }
      reg.define("Hash", :map, ["Hash"], block: :required) { |h, &b| h.map { |k, v| b.(pair(k, v)) } }
      %i[select filter reject].each do |m|
        reg.define("Hash", m, ["Hash"], block: :required) { |h, &b| h.public_send(m) { |k, v| Values.truthy?(b.(pair(k, v))) } }
      end
      %i[any? all? none?].each do |m|
        reg.define("Hash", m, ["Hash"], block: :required) { |h, &b| h.public_send(m) { |k, v| Values.truthy?(b.(pair(k, v))) } }
      end
      reg.define("Hash", :count, ["Hash"], block: :optional) { |h, &b| b ? h.count { |k, v| Values.truthy?(b.(pair(k, v))) } : h.size }
      %i[find detect].each do |m|
        reg.define("Hash", m, ["Hash"], block: :required) { |h, &b| (kv = h.find { |k, v| Values.truthy?(b.(pair(k, v))) }) && pair(*kv) }
      end
      %i[min_by max_by].each do |m|
        reg.define("Hash", m, ["Hash"], block: :required) do |h, &b|
          ks = []
          kv = sort_checked(h.values, ks) { h.public_send(m) { |k, v| ks << b.(pair(k, v)); ks[-1] } }
          kv && pair(*kv)
        end
      end
      reg.define("Hash", :sort_by, ["Hash"], block: :required) do |h, &b|
        ks = []
        sort_checked(h.values, ks) { h.sort_by { |k, v| ks << b.(pair(k, v)); ks[-1] } }.map { |k, v| pair(k, v) }
      end
      reg.define("Hash", :sum, ["Hash"], optional: [NUMERIC], block: :required) { |h, init = 0, &b| h.sum(init) { |k, v| b.(pair(k, v)) } }
      reg.define("Hash", :transform_values, ["Hash"], block: :required) { |h, &b| h.transform_values { b.(_1) } }
      reg.define("Hash", :transform_keys, ["Hash"], block: :required) { |h, &b| h.each_with_object({}) { |(k, v), r| r[key!(b.(k))] = v } }
    end

    def install_set(reg)
      reg.define("Set", CTOR, [], rest: "Any") { |*xs| Set.new(xs.map { key!(_1) }) }
      reg.define("Set", :length, ["Set"], &:length)
      reg.define("Set", :size, ["Set"], &:size)
      reg.define("Set", :empty?, ["Set"], &:empty?)
      %i[include? member?].each { |m| reg.define("Set", m, %w[Set Any]) { |s, x| s.include?(x) } }
      reg.define("Set", :add, %w[Set Any]) { |s, x| s.add(key!(x)) }
      reg.define("Set", :add?, %w[Set Any]) { |s, x| s.add?(key!(x)) }
      reg.define("Set", :delete, %w[Set Any]) { |s, x| s.delete(x) }
      reg.define("Set", :to_a, ["Set"], &:to_a)
      reg.define("Set", :each, ["Set"], block: :required) { |s, &b| s.each { b.(_1) }; s }
      reg.define("Set", :map, ["Set"], block: :required) { |s, &b| s.map { b.(_1) } }
      %i[select filter reject].each do |m|
        reg.define("Set", m, ["Set"], block: :required) { |s, &b| s.public_send(m) { Values.truthy?(b.(_1)) } }
      end
      %i[union intersection difference].each { |m| reg.define("Set", m, %w[Set Set]) { |a, c| a.public_send(m, c) } }
      %i[subset? superset? disjoint? intersect?].each { |m| reg.define("Set", m, %w[Set Set]) { |a, c| a.public_send(m, c) } }
    end

    STR_OR_RE = %w[String Regexp].freeze

    def install_regexp(reg)
      reg.define("Regexp", :new, ["String"], optional: ["String"]) do |s, flags = ""| # flags: letters of "imxn", as the literal's
        raise Fail.new("ArgumentError", "unknown regexp option: #{flags}") unless flags.match?(/\A[imxn]*\z/)
        bits = { "i" => Regexp::IGNORECASE, "m" => Regexp::MULTILINE, "x" => Regexp::EXTENDED, "n" => Regexp::NOENCODING }
        ruby_error("RegexpError") { Regexp.new(s, flags.each_char.sum { bits.fetch(_1) }) }
      end
      reg.define("Regexp", :escape, ["String"]) { |s| Regexp.escape(s) }
      reg.define("Regexp", :source, ["Regexp"], &:source)
      reg.define("Regexp", :match, %w[Regexp String]) { |r, s| r.match(s) }
      reg.define("Regexp", :match?, %w[Regexp String]) { |r, s| r.match?(s) }
      reg.define("String", :match, ["String", STR_OR_RE]) { |s, r| s.match(r) }
      reg.define("String", :match?, ["String", STR_OR_RE]) { |s, r| s.match?(r) }
      reg.define("String", :scan, ["String", STR_OR_RE]) { |s, r| s.scan(r).map { _1.is_a?(Array) ? Tuple.new(_1) : _1 } }
      reg.define("MatchData", :captures, ["MatchData"], &:captures)
      reg.define("MatchData", :named_captures, ["MatchData"], &:named_captures)
      reg.define("MatchData", :names, ["MatchData"], &:names)
      reg.define("MatchData", :to_a, ["MatchData"], &:to_a)
      reg.define("MatchData", :to_s, ["MatchData"], &:to_s)
      reg.define("MatchData", :pre_match, ["MatchData"], &:pre_match)
      reg.define("MatchData", :post_match, ["MatchData"], &:post_match)
      reg.define("MatchData", :begin, %w[MatchData Integer]) { |m, i| m.begin(i) }
      reg.define("MatchData", :end, %w[MatchData Integer]) { |m, i| m.end(i) }
    end

    def install_io(reg, input)
      reg.define("Kernel", :gets, []) { input.gets }
      reg.define("File", :read, ["String"]) { |path| io_error { File.read(path) } }
      reg.define("File", :readlines, ["String"]) { |path| io_error { File.readlines(path) } }
      reg.define("File", :write, %w[String String]) { |path, s| io_error { File.write(path, s) } }
      reg.define("File", :exist?, ["String"]) { |path| File.exist?(path) }
    end

    def io_error
      yield
    rescue SystemCallError, IOError => e
      raise Fail.new("IOError", e.message)
    end

    def install_more_kernel(reg)
      %i[format sprintf].each do |m|
        # %s uses each value's to_s, including a type's own; other directives need numbers or Strings.
        reg.define("Kernel", m, ["String"], rest: "Any") do |f, *xs|
          format(f, *xs.map { _1.is_a?(RecordValue) ? format_arg(_1) : _1 })
        rescue ::ArgumentError, ::TypeError, ::KeyError => e
          raise Fail.new("ArgumentError", e.message)
        end
      end
      # Every type includes Kernel: these show a value with its type's own to_s / inspect, if any.
      reg.define("Kernel", :to_s, ["Any"]) { |x| Values.to_s(x) }
      reg.define("Kernel", :inspect, ["Any"]) { |x| Values.inspect(x) }
      reg.define("Kernel", :pp, ["Any"]) { |v| reg.lookup("Kernel", "p").impl.(v) }
      # rand(n): an Integer in 0...n for an Integer n, a Float in 0.0...n for a Float n (Ruby's Random.rand: n must be positive).
      reg.define("Kernel", :rand, [], optional: [%w[Integer Float]]) { |n = nil| n ? Random.rand(n) : rand }
      reg.define("Kernel", :Integer, [%w[String Integer Float]]) { |x| ruby_error("ArgumentError") { Integer(x) } }
      reg.define("Kernel", :Float, [%w[String Integer Float]]) { |x| ruby_error("ArgumentError") { Float(x) } }
    end

    def install_more_numeric(reg)
      reg.define("Integer", :divmod, %w[Integer Integer]) { |a, b| int_div(:divmod, a, b).then { Tuple.new(_1) } }
      reg.define("Integer", :gcd, %w[Integer Integer]) { |a, b| a.gcd(b) }
      reg.define("Integer", :lcm, %w[Integer Integer]) { |a, b| a.lcm(b) }
      reg.define("Integer", :pow, %w[Integer Integer], optional: ["Integer"]) { |a, b, m = nil| m ? a.pow(b, m) : int_pow(a, b) }
      reg.define("Integer", :digits, ["Integer"]) { |n| TypedArray.new("Integer", n.digits) } # Math::DomainError when negative
      reg.define("Integer", :bit_length, ["Integer"], &:bit_length)
      reg.define("Integer", :chr, ["Integer"]) { |n| ruby_error("RangeError") { n.chr } }
      reg.define("Integer", :sqrt, ["Integer"]) { |n| ruby_error("Math::DomainError") { Integer.sqrt(n) } }
      reg.define("Integer", :clamp, %w[Integer Integer Integer]) { |n, lo, hi| n.clamp(lo, hi) }
      reg.define("Integer", :between?, %w[Integer Integer Integer]) { |n, lo, hi| n.between?(lo, hi) }
      reg.define("Float", :truncate, ["Float"]) { |f| float_to_i(f, &:truncate) }
      reg.define("Float", :divmod, %w[Float Any]) do |a, b| # the divisor may be an Integer, as Ruby's
        raise Fail.new("TypeError", "argument 2 must be Float or Integer, got #{Values.describe(b)}") unless b.is_a?(Float) || b.is_a?(Integer)
        raise Fail.new("ZeroDivisionError", "divided by 0") if b == 0 && b.is_a?(Integer)
        Tuple.new(a.divmod(b))
      end
      reg.define("Float", :finite?, ["Float"], &:finite?)
      reg.define("Float", :infinite?, ["Float"], &:infinite?)
      reg.define("Float", :clamp, %w[Float Float Float]) { |n, lo, hi| n.clamp(lo, hi) }
    end

    def install_more_string(reg)
      # Bytes and encodings, as Ruby: Array.pack(bytes, "C*") is binary, force_encoding relabels it.
      reg.define("Array", :pack, %w[Array String]) { |a, fmt| ruby_error("ArgumentError") { a.pack(fmt) }.then { _1.frozen? ? _1 : _1 } }
      reg.define("String", :force_encoding, %w[String String]) { |s, enc| ruby_error("ArgumentError") { s.force_encoding(enc) } } # in place, as Ruby's
      reg.define("String", :valid_encoding?, ["String"], &:valid_encoding?)
      reg.define("String", :encoding, ["String"]) { |s| s.encoding.name }
      reg.define("String", :center, %w[String Integer], optional: ["String"]) { |s, n, pad = " "| s.center(n, pad) }
      reg.define("String", :tr, %w[String String String]) { |s, a, b| s.tr(a, b) }
      reg.define("String", :delete, %w[String String], rest: "String") { |s, t, *ts| s.delete(t, *ts) } # as delete!
      reg.define("String", :squeeze, ["String"], rest: "String") { |s, *chars| s.squeeze(*chars) } # as squeeze!
      reg.define("String", :ord, ["String"]) { |s| ruby_error("ArgumentError") { s.ord } }
      %i[succ next].each { |m| reg.define("String", m, ["String"], &:succ) }
      reg.define("String", :bytes, ["String"], &:bytes)
      reg.define("String", :hex, ["String"], &:hex)
      reg.define("String", :oct, ["String"], &:oct)
      reg.define("String", :each_line, ["String"], block: :required) { |s, &b| s.each_line { b.(_1) }; s }
      reg.lookup("String", "sub").params[1] = STR_OR_RE
      reg.lookup("String", "gsub").params[1] = STR_OR_RE
      reg.lookup("String", "index").params[1] = STR_OR_RE
      reg.lookup("String", "split").optional[0] = STR_OR_RE
    end

    def install_more_array(reg)
      reg.define("Array", :zip, ["Array"], rest: "Array") { |a, *bs| a.zip(*bs).map { Tuple.new(_1) } }
      # Without a block, the slices as an Array of Arrays (Ruby's each_slice(2).map ...).
      %i[each_slice each_cons].each do |m|
        reg.define("Array", m, %w[Array Integer], block: :optional) do |a, n, &b|
          nonneg(n)
          next a.to_a.public_send(m, n).to_a unless b
          a.public_send(m, n) { b.(_1) }
          a
        end
      end
      # A Tuple is an Array in Ruby, so flatten opens it too (`String.scan` with groups gives Tuples).
      reg.define("Array", :flatten, ["Array"]) { |a| flatten_all(a) }
      reg.define("Array", :flatten!, ["Array"]) { |a| (f = flatten_all(a)) == a ? nil : a.replace(f) }
      reg.define("Array", :compact, ["Array"], &:compact)
      # Struct values compare by their type's == (fields by default), not by Ruby's hash/eql?.
      reg.define("Array", :uniq, ["Array"]) do |a|
        next a.uniq unless a.any? { _1.is_a?(StructValue) || _1.is_a?(Tuple) || _1.is_a?(RecordValue) }
        a.each_with_object([]) { |x, out| out << x unless out.include?(x) }
      end
      reg.define("Array", :tally, ["Array"]) { |a| a.each_with_object(Hash.new(0)) { |x, h| h[key!(x)] += 1 }.then { Hash[_1] } }
      reg.define("Array", :group_by, ["Array"], block: :required) do |a, &b|
        a.each_with_object({}) { |x, h| (h[key!(b.(x))] ||= []) << x }
      end
      reg.define("Array", :partition, ["Array"], block: :required) { |a, &b| Tuple.new(a.partition { Values.truthy?(b.(_1)) }) }
      reg.define("Array", :flat_map, ["Array"], block: :required) { |a, &b| a.flat_map { array_result(b.(_1)) } }
      # rfind(a) { }: the last element the block accepts (Ruby 4.0's Array#rfind, written out).
      reg.define("Array", :rfind, ["Array"], block: :required) { |a, &b| a.reverse_each.find { Values.truthy?(b.(_1)) } }
      reg.define("Array", :each_with_object, %w[Array Any], block: :required) { |a, memo, &b| a.each { b.(_1, memo) }; memo }
      # `sum(xs, 0.0)`: as Ruby, the initial value (default 0) is the result for an empty collection.
      # Elements of a type that includes Arithmetic are added with its own + (Interpreter#call_builtin).
      reg.define("Array", :sum, ["Array"], optional: ["Any"], block: :optional) do |a, init = 0, &b|
        xs = b ? a.map { b.(_1) } : a
        raise Fail.new("TypeError", "the initial value must be a number, got #{Values.describe(init)}") unless NUMERIC.include?(Values.type_of(init))
        xs.each { |x| raise Fail.new("TypeError", "element must be a number, got #{Values.describe(x)}") unless NUMERIC.include?(Values.type_of(x)) }
        xs.sum(init)
      end
      reg.define("Array", :rotate, ["Array"], optional: ["Integer"]) { |a, n = 1| a.rotate(n) }
      reg.define("Array", :sample, ["Array"], &:sample)
      reg.define("Array", :shuffle, ["Array"], &:shuffle)
      reg.define("Array", :product, %w[Array Array]) { |a, b| a.product(b).map { Tuple.new(_1) } }
      reg.define("Array", :to_h, ["Array"]) do |a|
        a.each_with_object({}) do |t, h|
          raise Fail.new("TypeError", "Array.to_h needs [key, value] Tuples, got #{Values.describe(t)}") unless t.is_a?(Tuple) && t.elems.size == 2
          h[key!(t.elems[0])] = t.elems[1]
        end
      end
      reg.define("Array", :delete, %w[Array Any]) { |a, x| a.delete(x) }
      reg.define("Array", :delete_at, %w[Array Integer]) { |a, i| a.delete_at(i) }
      reg.define("Array", :delete_if, ["Array"], block: :required) { |a, &b| a.delete_if { Values.truthy?(b.(_1)) } }
      # insert past the end would fill the gap with nil (Ruby): an IndexError here, as `a[k] = v` past the end is.
      reg.define("Array", :insert, %w[Array Integer], rest: "Any") do |a, i, *xs|
        raise Fail.new("IndexError", "index #{i} is past the end of the Array (length #{a.size}); the gap would be nil") if i > a.size
        raise Fail.new("IndexError", "index #{i} is before the start of the Array (length #{a.size})") if i < -a.size - 1
        a.insert(i, *check_elems(a, xs))
      end
      reg.define("Array", :dig, %w[Array Integer], rest: "Any") { |a, k, *ks| dig_into(a, [k, *ks]) }
      # ENV.replace(h): the whole environment becomes h; checked before anything changes (String keys and values).
      reg.define("ENV", :replace, ["Hash"]) do |h|
        h.each do |k, v|
          raise Fail.new("TypeError", "keys and values must be String, got #{Values.describe(k)} => #{Values.describe(v)}") unless k.is_a?(String) && v.is_a?(String)
        end
        ENV.replace(h)
        nil
      end
      reg.define("Array", :clear, ["Array"], &:clear)
      reg.define("Array", :dup, ["Array"]) { |a| a.is_a?(TypedArray) ? TypedArray.new(a.elem_type, a.to_a) : a.dup }
      count = reg.lookup("Array", "count")
      count.block = :optional
      count.optional = ["Any"]
      count.impl = ->(a, *x, &b) { b ? a.count { Values.truthy?(b.(_1)) } : (x.empty? ? a.size : a.count(x[0])) }
      reg.define("Tuple", :to_a, ["Tuple"]) { |t| t.elems.dup }
    end
  end
end

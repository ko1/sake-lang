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
    end

    def int_pow(a, b)
      raise Fail.new("ArgumentError", "negative exponent #{b} for Integer ** Integer (Sake has no Rational)") if b.negative?
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
      reg.add_namespace("BinaryOp")
    end

    # `Integer.+(a, b)` etc.: the operator with both operands fixed to the type.
    def install_typed_ops(reg, type, ops)
      ops.each do |op|
        impl = reg.binary_ops[op.to_s][[type, type]] or raise "BUG: no row #{op} #{type}"
        reg.define(type, op, [type, type]) { |a, b| impl.(a, b) }
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
      reg.define("String", :each_char, ["String"], block: :required) { |s, &b| s.each_char { b.(_1) }; s }
      reg.define("String", :ljust, %w[String Integer], optional: ["String"]) { |s, n, pad = " "| s.ljust(n, pad) }
      reg.define("String", :rjust, %w[String Integer], optional: ["String"]) { |s, n, pad = " "| s.rjust(n, pad) }
    end

    def install_array(reg)
      reg.define("Array", :[], [], rest: "Any") { |*xs| xs }
      reg.define("Array", :length, ["Array"], &:length)
      reg.define("Array", :size, ["Array"], &:size)
      reg.define("Array", :empty?, ["Array"], &:empty?)
      reg.define("Array", :push, ["Array"], rest: "Any") { |a, *xs| a.push(*xs) }
      reg.define("Array", :append, ["Array"], rest: "Any") { |a, *xs| a.push(*xs) }
      reg.define("Array", :concat, %w[Array Array]) { |a, b| a.concat(b) }
      reg.define("Array", :include?, %w[Array Any]) { |a, x| a.include?(x) }
      reg.define("Array", :join, ["Array"], optional: ["String"]) { |a, sep = ""| a.map { Values.to_s(_1) }.join(sep) }
      reg.define("Array", :reverse, ["Array"], &:reverse)
      reg.define("Array", :sum, ["Array"]) do |a|
        a.each { |x| raise Fail.new("TypeError", "Array.sum: element must be Integer or Float, got #{Values.describe(x)}") unless NUM.include?(Values.type_of(x)) }
        a.sum
      end
      reg.define("Array", :sort, ["Array"]) { |a| sort_checked(a) { a.sort } }
      reg.define("Array", :sort_by, ["Array"], block: :required) { |a, &b| sort_checked(a) { a.sort_by { b.(_1) } } }
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
      reg.define("Array", :count, ["Array"], block: :required) { |a, &b| a.count { Values.truthy?(b.(_1)) } }
      %i[reduce inject].each do |m|
        reg.define("Array", m, %w[Array Any], block: :required) { |a, init, &b| a.reduce(init) { |acc, x| b.(acc, x) } }
      end
    end

    def nonneg(n)
      raise Fail.new("ArgumentError", "negative size #{n}") if n.negative?
      true
    end

    def sort_checked(a)
      yield
    rescue ArgumentError, NoMethodError
      types = a.map { Values.describe(_1) }.uniq
      raise Fail.new("ArgumentError", "cannot compare elements of types #{types.join(", ")}")
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

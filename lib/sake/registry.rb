# frozen_string_literal: true

module Sake
  # The internal name of a constructor written `T[...]`; it cannot clash with `[]`, the index operation.
  CTOR = "new[]"

  # A built-in operation `Namespace.name`. Each param is a type name, "Any", or an Array of type names.
  # keywords: name => type of each optional keyword argument (`Time.at(t, in: "+09:00")`).
  Builtin = Struct.new(:namespace, :name, :params, :optional, :rest, :block, :impl, :keywords, keyword_init: true) do
    def full_name = name == CTOR ? "#{namespace}[]" : "#{namespace}.#{name}"
    def min_arity = params.size
    def max_arity = rest ? Float::INFINITY : params.size + optional.size
    def keyword_types = keywords || {}

    # `Array.sum(x, [Integer|Float]) [{ }]`: x is the subject, [T] optional, *T rest, { } a block.
    def signature
      ps = params.each_with_index.map { |t, i| i.zero? && t == namespace ? "x" : Array(t).join("|") }
      ps += optional.map { "[#{Array(_1).join("|")}]" }
      ps << "*#{Array(rest).join("|")}" if rest
      ps += keyword_types.map { |k, t| "[#{k}: #{Array(t).join("|")}]" }
      blk = { required: " { }", optional: " [{ }]" }.fetch(block, "")
      name == CTOR ? "#{namespace}[#{ps.join(", ")}]" : "#{full_name}(#{ps.join(", ")})#{blk}"
    end

    def param_type(i)
      if i < params.size then params[i]
      elsif i < params.size + optional.size then optional[i - params.size]
      else rest
      end
    end
  end

  # Raised inside a builtin's implementation; the interpreter attaches the line.
  class Fail < StandardError
    attr_reader :kind

    def initialize(kind, message)
      @kind = kind
      super(message)
    end
  end

  # Namespace => name => Builtin, plus the closed BinaryOp table.
  class Registry
    attr_reader :binary_ops, :unary_ops

    def initialize
      @ns = Hash.new { |h, k| h[k] = {} }
      @binary_ops = Hash.new { |h, k| h[k] = {} }
      @unary_ops = Hash.new { |h, k| h[k] = {} }
    end

    def define(ns, name, params, optional: [], rest: nil, block: :none, keywords: {}, &impl)
      @ns[ns][name.to_s] = Builtin.new(namespace: ns, name: name.to_s, params:, optional:, rest:, block:, keywords:, impl: strict(impl))
    end

    # A proc with several parameters splats a lone Array argument (`|a, sep = ""|` given [1, 2] sees
    # a = 1); a method made from it takes its arguments as given, with the same self.
    def strict(impl)
      return impl if impl.lambda? || impl.parameters.size < 2
      owner = impl.binding.receiver
      name = :"__sake_builtin_#{impl.object_id}"
      owner.define_singleton_method(name, &impl)
      owner.method(name)
    end

    def define_binary(op, t1, t2, &impl)
      @binary_ops[op.to_s][[t1, t2]] = impl
    end

    # `-x`, `+x`, `~x` for a built-in type t (the result has the type of x).
    def define_unary(op, t, &impl)
      @unary_ops[op.to_s][t] = impl
    end

    def namespace?(ns) = @ns.key?(ns)
    def add_namespace(ns) = @ns[ns]
    def lookup(ns, name) = @ns.fetch(ns, {})[name.to_s]
    def undefine(ns, name) = @ns[ns].delete(name.to_s)
    def names(ns) = @ns.fetch(ns, {}).keys
    def namespaces = @ns.keys

    def namespaces_defining(name)
      @ns.select { |_, fs| fs.key?(name.to_s) }.keys
    end
  end
end

# frozen_string_literal: true

module Sake
  # A built-in operation `Namespace.name`. Each param is a type name, "Any", or an Array of type names.
  Builtin = Struct.new(:namespace, :name, :params, :optional, :rest, :block, :impl, keyword_init: true) do
    def full_name = name == "[]" ? "#{namespace}[]" : "#{namespace}.#{name}"
    def min_arity = params.size
    def max_arity = rest ? Float::INFINITY : params.size + optional.size

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
    attr_reader :binary_ops

    def initialize
      @ns = Hash.new { |h, k| h[k] = {} }
      @binary_ops = Hash.new { |h, k| h[k] = {} }
    end

    def define(ns, name, params, optional: [], rest: nil, block: :none, &impl)
      @ns[ns][name.to_s] = Builtin.new(namespace: ns, name: name.to_s, params:, optional:, rest:, block:, impl:)
    end

    def define_binary(op, t1, t2, &impl)
      @binary_ops[op.to_s][[t1, t2]] = impl
    end

    def namespace?(ns) = @ns.key?(ns)
    def add_namespace(ns) = @ns[ns]
    def lookup(ns, name) = @ns.fetch(ns, {})[name.to_s]
    def names(ns) = @ns.fetch(ns, {}).keys
    def namespaces = @ns.keys

    def namespaces_defining(name)
      @ns.select { |_, fs| fs.key?(name.to_s) }.keys
    end
  end
end

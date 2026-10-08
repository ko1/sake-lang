# frozen_string_literal: true

require_relative 'ast'
require_relative 'errors'
require_relative 'functions'
require_relative 'values'

module SQL
  # Where names are looked up: the columns of one table (or none) and, optionally, result-column
  # aliases (name -> expression) that a name falls back to when it is no column.
  class Scope
    attr_reader :table, :aliases

    def initialize(table = nil, aliases = {})
      @table = table
      @aliases = aliases
    end

    EMPTY = new.freeze
  end

  # A compiled expression: `fn.call(row)` gives the value; `affinity` is :integer, :real,
  # :text or nil (1.9).
  Compiled = Struct.new(:fn, :affinity)

  # Turns an expression AST into a Compiled one. Every name and function is checked here,
  # so name errors happen before any row is read.
  class Compiler
    COMPARISONS = {
      eq: ->(c) { c.zero? }, ne: ->(c) { !c.zero? },
      lt: ->(c) { c < 0 }, le: ->(c) { c <= 0 },
      gt: ->(c) { c > 0 }, ge: ->(c) { c >= 0 }
    }.freeze

    def initialize(scope)
      @scope = scope
    end

    def compile(node)
      case node
      when Literal then constant(node.value)
      when ColumnRef then compile_column(node)
      when Unary then compile_unary(node)
      when Binary then compile_binary(node)
      when Call then compile_call(node)
      else raise ArgumentError, "unknown expression #{node.inspect}"
      end
    end

    private

    def constant(v) = Compiled.new(->(_row) { v }, nil)

    def compile_column(node)
      table = @scope.table
      label = node.table ? "#{node.table}.#{node.name}" : node.name
      if table && (node.table.nil? || node.table.casecmp?(table.name))
        if (i = table.column_index(node.name))
          return Compiled.new(->(row) { row[i] }, table.columns[i].type)
        end
      end
      if node.table.nil? && (expr = @scope.aliases[node.name.downcase])
        return Compiler.new(Scope.new(table)).compile(expr)
      end

      raise SqlError, "no such column: #{label}"
    end

    def compile_unary(node)
      operand = compile(node.operand).fn
      fn =
        case node.op
        when :neg then lambda { |row|
          v = Values.to_number(operand.call(row))
          v.nil? ? nil : -v
        }
        when :pos then operand
        when :not then ->(row) { Values.from_bool((t = Values.truth(operand.call(row))).nil? ? nil : !t) }
        end
      Compiled.new(fn, nil)
    end

    def compile_binary(node)
      l = compile(node.left)
      r = compile(node.right)
      fn =
        case node.op
        when :and, :or then logic(node.op, l.fn, r.fn)
        when :add, :sub, :mul, :div, :mod then arithmetic(node.op, l.fn, r.fn)
        when :concat then concat(l.fn, r.fn)
        when :is, :is_not then identity(node.op == :is_not, l, r)
        else comparison(COMPARISONS.fetch(node.op), l, r)
        end
      Compiled.new(fn, nil)
    end

    def logic(op, lf, rf)
      lambda do |row|
        a = Values.truth(lf.call(row))
        b = Values.truth(rf.call(row))
        if op == :and
          Values.from_bool(a == false || b == false ? false : (a.nil? || b.nil? ? nil : true))
        else
          Values.from_bool(a == true || b == true ? true : (a.nil? || b.nil? ? nil : false))
        end
      end
    end

    def comparison(test, l, r)
      lambda do |row|
        c = Values.compare(l.fn.call(row), l.affinity, r.fn.call(row), r.affinity)
        c.nil? ? nil : (test.call(c) ? 1 : 0)
      end
    end

    def identity(negated, l, r)
      lambda do |row|
        same = Values.same?(l.fn.call(row), l.affinity, r.fn.call(row), r.affinity)
        same == negated ? 0 : 1
      end
    end

    def concat(lf, rf)
      lambda do |row|
        a = lf.call(row)
        b = rf.call(row)
        a.nil? || b.nil? ? nil : Values.text_form(a) + Values.text_form(b)
      end
    end

    def arithmetic(op, lf, rf)
      lambda do |row|
        a = Values.to_number(lf.call(row))
        b = Values.to_number(rf.call(row))
        a.nil? || b.nil? ? nil : Arithmetic.apply(op, a, b)
      end
    end

    def compile_call(node)
      fn = Functions.lookup(node.name) or raise SqlError, "no such function: #{node.name}"
      unless fn.arity.cover?(node.args.size)
        raise SqlError, "wrong number of arguments to function #{node.name}()"
      end

      args = node.args.map { |a| compile(a).fn }
      Compiled.new(->(row) { fn.impl.call(args.map { |a| a.call(row) }) }, nil)
    end
  end

  # + - * / % on numbers (1.8).
  module Arithmetic
    module_function

    def apply(op, a, b)
      a.is_a?(Integer) && b.is_a?(Integer) ? integer_op(op, a, b) : real_op(op, a, b)
    end

    def integer_op(op, a, b)
      case op
      when :add then a + b
      when :sub then a - b
      when :mul then a * b
      when :div then b.zero? ? nil : (a.abs / b.abs) * (a.negative? == b.negative? ? 1 : -1)
      when :mod then b.zero? ? nil : a.remainder(b)
      end
    end

    def real_op(op, a, b)
      case op
      when :add then a.to_f + b
      when :sub then a.to_f - b
      when :mul then a.to_f * b
      when :div then b.zero? ? nil : a.to_f / b
      when :mod
        x = a.to_i
        y = b.to_i
        y.zero? ? nil : x.remainder(y).to_f
      end
    end
  end
end

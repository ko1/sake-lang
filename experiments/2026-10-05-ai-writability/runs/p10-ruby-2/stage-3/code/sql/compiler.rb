# frozen_string_literal: true

require_relative 'aggregates'
require_relative 'ast'
require_relative 'errors'
require_relative 'functions'
require_relative 'values'

module SQL
  # Where names are looked up: the columns of one table (or none) and, optionally, result-column
  # aliases (name -> expression) that a name falls back to when it is no column.
  # `aggregates` maps a normalized aggregate Call (Aggregates.key) to the row slot holding its value;
  # nil where aggregate calls are not allowed, and `misuse` (:function, :plain, :group_by) picks
  # the error then (3.3).
  class Scope
    attr_reader :table, :aliases, :aggregates

    def initialize(table = nil, aliases = {}, aggregates: nil, misuse: :function)
      @table = table
      @aliases = aliases
      @aggregates = aggregates
      @misuse = misuse
    end

    # The same scope for the body of an alias: names in it are columns only.
    def without_aliases = Scope.new(@table, {}, aggregates: @aggregates, misuse: @misuse)

    def misuse_error(name, via_alias: false)
      case @misuse
      when :group_by then SqlError.new('aggregate functions are not allowed in the GROUP BY clause')
      when :plain then SqlError.new("misuse of aggregate: #{name}()")
      else SqlError.new(via_alias ? "misuse of aggregate: #{name}()" : "misuse of aggregate function #{name}()")
      end
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
      when CaseExpr then compile_case(node)
      when Between then compile_between(node)
      when InList then compile_in(node)
      when Like then compile_like(node)
      when Cast then compile_cast(node)
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
        if @scope.aggregates.nil? && (call = Aggregates.find_calls(expr).first)
          raise @scope.misuse_error(call.name, via_alias: true)
        end

        return Compiler.new(@scope.without_aliases).compile(expr)
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
        when :not then ->(row) { Values.from_bool(Values.not3(Values.truth(operand.call(row)))) }
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
        Values.from_bool(op == :and ? Values.and3(a, b) : Values.or3(a, b))
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

    def compile_case(node)
      whens = node.whens.map { |cond, result| [compile(cond), compile(result).fn] }
      else_fn = node.else_expr ? compile(node.else_expr).fn : ->(_row) {}
      fn =
        if node.operand
          operand = compile(node.operand)
          lambda do |row|
            x = operand.fn.call(row)
            hit = whens.find do |value, _|
              (c = Values.compare(x, operand.affinity, value.fn.call(row), value.affinity)) && c.zero?
            end
            (hit ? hit[1] : else_fn).call(row)
          end
        else
          lambda do |row|
            hit = whens.find { |cond, _| Values.truth(cond.fn.call(row)) == true }
            (hit ? hit[1] : else_fn).call(row)
          end
        end
      Compiled.new(fn, nil)
    end

    # x >= low AND x <= high, three-valued, x evaluated once.
    def compile_between(node)
      x = compile(node.expr)
      low = compile(node.low)
      high = compile(node.high)
      fn = lambda do |row|
        v = x.fn.call(row)
        lo = Values.compare(v, x.affinity, low.fn.call(row), low.affinity)
        hi = Values.compare(v, x.affinity, high.fn.call(row), high.affinity)
        inside = Values.and3(lo && lo >= 0, hi && hi <= 0)
        Values.from_bool(node.negated ? Values.not3(inside) : inside)
      end
      Compiled.new(fn, nil)
    end

    # Only x's affinity counts: each item is converted to it; no affinity, no conversion.
    def compile_in(node)
      x = compile(node.expr)
      items = node.items.map { |i| compile(i).fn }
      fn = lambda do |row|
        v = x.fn.call(row)
        next nil if v.nil?

        candidates = items.map { |f| Values.convert_to_affinity(f.call(row), x.affinity) }
        found = candidates.any? { |c| !c.nil? && Values.order_compare(v, c).zero? }
        found_or_unknown = found || (candidates.any?(&:nil?) ? nil : false)
        Values.from_bool(node.negated ? Values.not3(found_or_unknown) : found_or_unknown)
      end
      Compiled.new(fn, nil)
    end

    def compile_like(node)
      x = compile(node.expr).fn
      pattern = compile(node.pattern).fn
      cache = {}
      fn = lambda do |row|
        a = x.call(row)
        p = pattern.call(row)
        next nil if a.nil? || p.nil?

        text = Values.text_form(p)
        re = cache[text] ||= like_regexp(text)
        Values.from_bool(re.match?(Values.text_form(a)) != node.negated)
      end
      Compiled.new(fn, nil)
    end

    # `%` any sequence, `_` one character, anything else itself ignoring ASCII case.
    def like_regexp(pattern)
      body = pattern.each_char.map do |ch|
        case ch
        when '%' then '.*'
        when '_' then '.'
        else Regexp.escape(ch)
        end
      end.join
      Regexp.new("\\A#{body}\\z", Regexp::IGNORECASE | Regexp::MULTILINE)
    end

    # An aggregate's value was computed per group into a slot of the group's row (SelectQuery).
    def compile_aggregate_call(node)
      slot = @scope.aggregates&.[](Aggregates.key(node)) or raise @scope.misuse_error(node.name)
      Compiled.new(->(row) { row[slot] }, nil)
    end

    def compile_cast(node)
      x = compile(node.expr).fn
      type = node.type
      Compiled.new(->(row) { Values.cast(x.call(row), type) }, type)
    end

    def compile_call(node)
      return compile_aggregate_call(node) if Aggregates.aggregate?(node)

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

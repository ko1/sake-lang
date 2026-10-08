# frozen_string_literal: true

require_relative 'aggregates'
require_relative 'ast'
require_relative 'errors'
require_relative 'functions'
require_relative 'scope'
require_relative 'values'

module SQL
  # A compiled expression: `fn.call(row)` gives the value; `affinity` is :integer, :real,
  # :text or nil (1.9).
  Compiled = Struct.new(:fn, :affinity)

  # Turns an expression AST into a Compiled one. Every name and function is checked here,
  # so name errors happen before any row is read. Subqueries are planned here too, with
  # QueryPlanner (not required above: it requires files that require this one).
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
      when ResolvedColumn then Compiled.new(->(row) { row[node.index] }, node.affinity)
      when Subquery then compile_scalar_subquery(node)
      when InSelect then compile_in_select(node)
      when Exists then compile_exists(node)
      else raise ArgumentError, "unknown expression #{node.inspect}"
      end
    end

    private

    def constant(v) = Compiled.new(->(_row) { v }, nil)

    # Looks the name up in this query's scope, then in each enclosing query's (4.2).
    def compile_column(node)
      crossed = []
      scope = @scope
      while scope
        found = node.table ? qualified_column(scope, node) : unqualified_column(scope, node)
        return crossed.empty? ? found : outer_reference(found, scope, crossed) if found

        crossed << scope.level
        scope = scope.level.parent
      end
      raise SqlError, "no such column: #{node.table ? "#{node.table}." : ''}#{node.name}"
    end

    # A column of an enclosing query is read from that query's current row.
    def outer_reference(compiled, scope, crossed)
      crossed.each { |level| level.correlation.flag = true }
      frame = scope.level.frame
      fn = compiled.fn
      Compiled.new(->(_row) { fn.call(frame.row) }, compiled.affinity)
    end

    def qualified_column(scope, node)
      source = scope.level.source_named(node.table) or return nil
      i = source.find(node.name) or raise SqlError, "no such column: #{node.table}.#{node.name}"
      slot(source.offset + i, source.columns[i])
    end

    def unqualified_column(scope, node)
      matches = scope.level.visible_columns(node.name)
      raise SqlError, "ambiguous column name: #{node.name}" if matches.size > 1
      return slot(*matches.first) unless matches.empty?

      expr = scope.aliases[node.name.downcase] or return nil
      if scope.aggregates.nil? && (call = Aggregates.find_calls(expr).first)
        raise scope.misuse_error(call.name, via_alias: true)
      end

      Compiler.new(scope.without_aliases).compile(expr)
    end

    def slot(index, column) = Compiled.new(->(row) { row[index] }, column.affinity)

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
      comparing = COMPARISONS.key?(node.op) || (%i[is is_not].include?(node.op) && !null_literal?(node))
      l = compile_operand(node.left, comparing)
      r = compile_operand(node.right, comparing)
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

    def null_literal?(node) = [node.left, node.right].any? { |n| n.is_a?(Literal) && n.value.nil? }

    # An operand of a comparison, BETWEEN or CASE x: a subquery with several columns is a row value.
    def compile_operand(node, comparing)
      node.is_a?(Subquery) ? compile_scalar_subquery(node, comparing:) : compile(node)
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
          operand = compile_operand(node.operand, true)
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
      x = compile_operand(node.expr, true)
      low = compile_operand(node.low, true)
      high = compile_operand(node.high, true)
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

    # --- subqueries (4.3) ---------------------------------------------------------------

    def plan_subquery(select) = QueryPlanner.plan(select, @scope.level.namespace, parent: @scope)

    # A subquery with one result column; it runs with the current row of this query in view.
    def single_column_subquery(select, comparing: false)
      sub = plan_subquery(select)
      unless sub.width == 1
        raise SqlError, comparing ? 'row value misused' : "sub-select returns #{sub.width} columns - expected 1"
      end

      sub
    end

    def compile_scalar_subquery(node, comparing: false)
      sub = single_column_subquery(node.select, comparing:)
      frame = @scope.level.frame
      fn = lambda do |row|
        frame.row = row
        sub.result_rows.dig(0, 0)
      end
      Compiled.new(fn, sub.affinities.first)
    end

    # As IN (v1, ...) but each comparison follows `x = v` with v's column affinity; an empty
    # subquery gives 0 even for a NULL x.
    def compile_in_select(node)
      x = compile(node.expr)
      sub = single_column_subquery(node.select)
      frame = @scope.level.frame
      value_affinity = sub.affinities.first
      fn = lambda do |row|
        frame.row = row
        values = sub.result_rows.map(&:first)
        next Values.from_bool(node.negated) if values.empty?

        v = x.fn.call(row)
        next nil if v.nil?

        cmps = values.map { |c| Values.compare(v, x.affinity, c, value_affinity) }
        found = cmps.any? { |c| c == 0 } || (cmps.any?(&:nil?) ? nil : false)
        Values.from_bool(node.negated ? Values.not3(found) : found)
      end
      Compiled.new(fn, nil)
    end

    def compile_exists(node)
      sub = plan_subquery(node.select)
      frame = @scope.level.frame
      Compiled.new(lambda { |row|
        frame.row = row
        sub.result_rows.empty? ? 0 : 1
      }, nil)
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

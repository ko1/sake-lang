# frozen_string_literal: true

require_relative 'ast'
require_relative 'collations'
require_relative 'errors'
require_relative 'limits'
require_relative 'ordering'
require_relative 'query'
require_relative 'values'

module SQL
  # UNION / UNION ALL / INTERSECT / EXCEPT of simple selects, left to right, with the ORDER BY / LIMIT
  # of the whole (SPEC 5.1). Rows are equal as in DISTINCT.
  class CompoundQuery
    include Query

    OPERATOR_NAMES = { union: 'UNION', union_all: 'UNION ALL', intersect: 'INTERSECT', except: 'EXCEPT' }.freeze

    def self.check_width(op, left, right)
      return if left.width == right.width

      raise SqlError, "SELECTs to the left and right of #{OPERATOR_NAMES.fetch(op)} " \
                      'do not have the same number of result columns'
    end

    def initialize(ast, namespace, parent: nil)
      @operators = []
      @parts = []
      plan_parts(ast, namespace, parent)
      @terms = ast.order_by.each_with_index.map { |t, i| order_term(t, i) }
      @limit, @offset = Limits.resolve(ast.limit, ast.offset, namespace)
    end

    def rows
      rows = @parts.first.rows
      @operators.each_with_index { |op, i| rows = combine(op, rows, @parts[i + 1].rows) }
      Limits.window(sorted(rows), @limit, @offset)
    end

    def correlated? = @parts.any?(&:correlated?)

    # Names and affinities are those of the first select.
    def result_names = @parts.first.result_names

    def affinities = @parts.first.affinities

    # Per column, that of the first part whose column has a collation (7.4), else none.
    def collations
      @collations ||= Array.new(width) do |k|
        @parts.map { |part| part.collations[k] }.find(&:collation) || Collations::NONE
      end
    end

    private

    # The parts are the simple selects at the leaves of the left-leaning tree, planned left to right.
    def plan_parts(ast, namespace, parent)
      chain = []
      node = ast
      while node.is_a?(Compound)
        chain.unshift([node.op, node.right])
        node = node.left
      end
      @parts << QueryPlanner.plan(node, namespace, parent:)
      chain.each do |op, select|
        part = QueryPlanner.plan(select, namespace, parent:)
        CompoundQuery.check_width(op, @parts.first, part)
        @operators << op
        @parts << part
      end
    end

    # A term is the k-th column, or the name of a result column of the first part that has it,
    # optionally followed by COLLATE.
    def order_term(term, position)
      expr = term.expr
      collation = nil
      if expr.is_a?(Collate)
        collation = Collations.resolve(expr.name)
        expr = expr.expr
      end
      index =
        if (k = Limits.ordinal(expr))
          Limits.ordinal_index(k, position, 'ORDER', width)
        elsif expr.is_a?(ColumnRef) && expr.table.nil?
          name_index(expr.name)
        end
      raise SqlError, "#{Limits.ordinal_word(position + 1)} ORDER BY term does not match any column in the result set" unless index

      Ordering::Term.new(term.desc, term.nulls, index, nil, collation || collations[index].collation)
    end

    def name_index(name)
      @parts.each do |part|
        i = part.result_names.index { |n| n&.casecmp?(name) }
        return i if i
      end
      nil
    end

    def sorted(rows)
      return rows if @terms.empty?

      Ordering.sort(rows.map { |r| [@terms.map { |t| t.key(nil, r) }, r] }, @terms).map(&:last)
    end

    def combine(op, left, right)
      case op
      when :union_all then left + right
      when :union then distinct(left + right)
      when :intersect
        keys = right.to_h { |r| [key(r), true] }
        distinct(left).select { |r| keys.key?(key(r)) }
      when :except
        keys = right.to_h { |r| [key(r), true] }
        distinct(left).reject { |r| keys.key?(key(r)) }
      end
    end

    def distinct(rows) = rows.uniq { |r| key(r) }

    def key(row) = row.each_with_index.map { |v, k| Values.group_key(v, collations[k].collation) }
  end
end

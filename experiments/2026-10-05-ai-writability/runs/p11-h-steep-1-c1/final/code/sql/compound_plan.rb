# frozen_string_literal: true

require_relative "ast"
require_relative "collation"
require_relative "error"
require_relative "plan"
require_relative "resolver"
require_relative "scope"
require_relative "select_plan"

module Sql
  # simple selects joined by UNION [ALL], INTERSECT or EXCEPT (spec 5.1), with the ORDER BY, LIMIT and
  # OFFSET of the whole. Its rows are those of the first part's width, so ORDER BY terms are
  # column positions (order_by holds ResolvedColumn terms).
  class CompoundPlan < Plan
    attr_reader :parts, :ops, :order_by, :limit, :offset

    def self.build(compound, namespace, parent)
      selects = compound.parts
      first = SelectPlan.build(selects.fetch(0), namespace, parent)
      parts = [first]
      compound.ops.each_with_index do |op, i|
        part = SelectPlan.build(selects.fetch(i + 1), namespace, parent)
        raise Error, "SELECTs to the left and right of #{op} do not have the same number of result columns" unless part.column_count == first.column_count

        parts << part
      end
      collations = Collation.merge(parts.map(&:result_collations), first.column_count)
      order_by = plan_order(compound.order_by, parts.map(&:result_names), collations)
      limit, offset = plan_bounds(compound.limit, compound.offset, namespace)
      new(parts, compound.ops, collations, order_by, limit, offset)
    end

    # The ORDER BY terms of a compound select: names_by_part has the result column names of each
    # part in order. A term is a column position or a name looked up in the first part, then the
    # next, and so on. A column is sorted under collations[k] unless the term has its own COLLATE.
    def self.plan_order(terms, names_by_part, collations)
      count = names_by_part.fetch(0).length
      terms.each_with_index.map do |term, i|
        expr = term.expr
        collate = expr.is_a?(Ast::Collate) ? expr : nil
        position = order_position(collate ? collate.operand : expr, i, count, names_by_part)
        column = Ast::ResolvedColumn.new(position, nil, collations.fetch(position)) #: Ast::Expr
        column = Ast::Collated.new(column, Collation.fetch(collate.name)) if collate
        Ast::OrderTerm.new(column, term.descending, term.nulls_first)
      end
    end

    def self.order_position(expr, index, count, names_by_part)
      position = SelectPlan.literal_position(expr)
      if position
        unless position >= 1 && position <= count
          raise Error, "#{SelectPlan.ordinal(index + 1)} ORDER BY term out of range - should be between 1 and #{count}"
        end

        return position - 1
      end
      if expr.is_a?(Ast::ColumnRef) && expr.qualifier.nil?
        key = Names.fold(expr.name)
        names_by_part.each do |names|
          found = names.index { |n| n && Names.fold(n) == key }
          return found if found
        end
      end
      raise Error, "#{SelectPlan.ordinal(index + 1)} ORDER BY term does not match any column in the result set"
    end

    # The resolved LIMIT and OFFSET expressions (nil: none).
    def self.plan_bounds(limit, offset, namespace)
      constants = Resolver.new(Scope.new(namespace, [], nil), {})
      [limit ? constants.resolve(limit) : nil, offset ? constants.resolve(offset) : nil]
    end

    def initialize(parts, ops, collations, order_by, limit, offset)
      super()
      @parts = parts
      @ops = ops
      @collations = collations
      @order_by = order_by
      @limit = limit
      @offset = offset
    end

    def column_count
      @parts.fetch(0).column_count
    end

    def result_names
      @parts.fetch(0).result_names
    end

    # The columns of a compound select have no affinity.
    def result_types
      Array.new(column_count, nil)
    end

    # The collation of each column is that of the first part with one (spec 7.4); never none.
    def result_collations
      list = [] #: Array[collation?]
      @collations.each { |collation| list << collation }
      list
    end

    def result_explicit
      Array.new(column_count, false)
    end

    def outer_width
      @parts.fetch(0).outer_width
    end
  end
end

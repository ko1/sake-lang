# frozen_string_literal: true

require_relative "ast"
require_relative "compound_plan"
require_relative "error"
require_relative "namespace"
require_relative "plan"
require_relative "select_plan"

module Sql
  # A recursive WITH table (spec 5.2): rows of initial, then rows of step run on each row in turn,
  # the row standing in step's FROM through feed. distinct (UNION, not UNION ALL) drops rows that
  # were queued before. A WITH table is not correlated, so there is no outer row to read.
  class RecursivePlan < Plan
    attr_reader :initial, :step, :feed, :distinct, :order_by, :limit, :offset, :collations

    # cte is the WITH table, compound its select (initial UNION [ALL] step), env the names its
    # select sees (not itself).
    def self.build(cte, compound, env)
      selects = compound.parts
      op = compound.ops.fetch(compound.ops.length - 1)
      raise Error, "recursive WITH table #{cte.name} must combine its selects with UNION or UNION ALL" unless op == "UNION" || op == "UNION ALL"

      initial = Planner.plan_body(initial_body(compound), env, nil)
      declared = cte.column_names
      raise Error, "table #{cte.name} has #{initial.column_count} values for #{declared.length} columns" if declared && declared.length != initial.column_count

      names = declared || initial.result_names #: Array[String?]
      feed = RowFeed.new
      step = SelectPlan.build(selects.fetch(selects.length - 1), env.with_working_table(WorkingTable.new(cte.name, names, feed)), nil)
      raise Error, "SELECTs to the left and right of #{op} do not have the same number of result columns" unless step.column_count == initial.column_count

      collations = CompoundPlan.merge_collations([initial.result_exprs, step.result_exprs])
      order_by = CompoundPlan.plan_order(compound.order_by, [names], collations)
      limit, offset = CompoundPlan.plan_bounds(compound.limit, compound.offset, env)
      new(initial, step, feed, op == "UNION", names, order_by, limit, offset, collations)
    end

    # The part of a recursive select before its last select: a select, or the compound of those before.
    def self.initial_body(compound)
      selects = compound.parts
      return selects.fetch(0) if selects.length == 2

      no_order = [] #: Array[Ast::OrderTerm]
      Ast::Compound.new(selects.first(selects.length - 1), compound.ops.first(compound.ops.length - 1), no_order, nil, nil)
    end

    def initialize(initial, step, feed, distinct, names, order_by, limit, offset, collations)
      super()
      @initial = initial
      @step = step
      @feed = feed
      @distinct = distinct
      @names = names
      @order_by = order_by
      @limit = limit
      @offset = offset
      @collations = collations
    end

    def column_count
      @names.length
    end

    def result_names
      @names
    end

    def result_types
      Array.new(@names.length, nil)
    end

    def result_exprs
      exprs = @collations.each_with_index.map { |collation, k| Ast::ResolvedColumn.new(k, nil, collation) } #: Array[Ast::Expr]
      exprs
    end

    def outer_width
      0
    end
  end
end

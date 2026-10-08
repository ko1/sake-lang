# frozen_string_literal: true

require_relative "ast"
require_relative "errors"
require_relative "identifier"
require_relative "scope"
require_relative "values"

module Sql
  # The planned things a FROM can name besides a Table (all "queries": they have `result_columns`,
  # `run(outer_row)` giving rows, and `volatile?`, true when the rows may differ between two runs of
  # one statement).

  # A query whose columns are renamed by a column list (a view's or a cte's).
  class NamedColumns
    def self.wrap(query, names, owner)
      return query unless names
      n = query.result_columns.length
      raise SqlError, "table #{owner} has #{n} values for #{names.length} columns" unless n == names.length
      new(query, names)
    end

    def initialize(query, names)
      @query = query
      @names = names
    end

    def result_columns
      @query.result_columns.zip(@names).map { |c, name| SourceColumn.new(name, c.type) }
    end

    def run(outer_row = [])
      @query.run(outer_row)
    end

    def volatile?
      @query.volatile?
    end
  end

  # The cte's own name inside the recursive part of a recursive cte (5.2): a table of the one row
  # being expanded. It quacks like a Table to FromClause (`columns`, `rows`).
  class WorkingTable
    attr_reader :columns
    attr_accessor :rows

    def initialize(columns)
      @columns = columns
      @rows = []
    end

    def volatile?
      true
    end

    def target
      self
    end
  end

  # A recursive cte (5.2), computed with a queue.
  class RecursiveCte
    # initial / step: planned queries; working: the WorkingTable `step` reads; distinct: UNION, not UNION ALL.
    def initialize(initial, step, working, distinct)
      @initial = initial
      @step = step
      @working = working
      @distinct = distinct
      @rows = nil
    end

    def result_columns
      @working.columns
    end

    def volatile?
      false
    end

    def run(_outer_row = [])
      @rows ||= compute
    end

    private

    def compute
      seen = {}
      queue = []
      add = lambda do |row|
        if @distinct
          key = Values.row_key(row)
          next if seen[key]
          seen[key] = true
        end
        queue << row
      end
      @initial.run([]).each(&add)
      result = []
      until queue.empty?
        row = queue.shift
        result << row
        @working.rows = [row]
        @step.run([]).each(&add)
      end
      result
    end
  end

  # A cte of a WITH, planned the first time it is used (so an unused one is never checked).
  # `planner` sees the ctes defined before it.
  class CteBinding
    def initialize(cte, recursive, planner)
      @cte = cte
      @recursive = recursive
      @planner = planner
      @target = nil
    end

    def target
      @target ||= recursive_parts ? plan_recursive(*recursive_parts) : plan_plain
    end

    private

    def plan_plain
      NamedColumns.wrap(@planner.plan(@cte.select, nil), @cte.columns, @cte.name)
    end

    def plan_recursive(initial_select, step_select, distinct)
      initial = NamedColumns.wrap(@planner.plan(initial_select, nil), @cte.columns, @cte.name)
      working = WorkingTable.new(initial.result_columns)
      step = @planner.with_binding(@cte.name, working).plan(step_select, nil)
      NamedColumns.wrap(step, working.columns.map(&:name), @cte.name) # the same width as the initial part
      RecursiveCte.new(initial, step, working, distinct)
    end

    # [initial select, recursive select, UNION (not ALL)?] if this cte is `initial UNION [ALL] recursive`
    # with the recursive part reading the cte; else nil (an ordinary cte).
    def recursive_parts
      return @parts if defined?(@parts)
      select = @cte.select
      @parts =
        if @recursive && select.is_a?(Compound) && %i[union union_all].include?(select.rest.last.first) &&
           select.order_by.empty? && reads?(select.rest.last.last)
          initial = if select.rest.length == 1 then select.first
                    else Compound.new(select.first, select.rest[0...-1], [], nil, nil)
                    end
          [initial, select.rest.last.last, select.rest.last.first == :union]
        end
    end

    # Does the FROM of the select name the cte (not looking inside subqueries)?
    def reads?(select)
      return false unless select.from
      items = [select.from.first, *select.from.joins.map(&:item)]
      items.any? { |item| item.is_a?(TableRef) && Sql.fold(item.name) == Sql.fold(@cte.name) }
    end
  end
end

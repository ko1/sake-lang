# frozen_string_literal: true

require_relative 'compound_query'
require_relative 'limits'
require_relative 'namespace'
require_relative 'query'
require_relative 'values'

module SQL
  # The rows of a recursive cte `initial UNION [ALL] recursive` (SPEC 5.2), computed with a queue.
  class RecursiveQuery
    include Query

    # The one row the cte stands for inside the recursive select.
    Working = Struct.new(:rows)

    def initialize(cte, namespace)
      ast = cte.query
      @union = ast.op == :union
      @initial = QueryPlanner.plan(ast.left, namespace)
      @working = Working.new([])
      itself = Relation.from_query(cte.name, @initial, cte.columns).with(rows: -> { @working.rows })
      @recursive = QueryPlanner.plan(ast.right, namespace.with_cte(cte.name, itself))
      CompoundQuery.check_width(ast.op, @initial, @recursive)
      @limit, @offset = Limits.resolve(ast.limit, ast.offset, namespace)
    end

    def rows
      queue = []
      seen = {}
      enqueue = lambda do |row|
        if @union
          key = row.map { |v| Values.group_key(v) }
          next if seen.key?(key)

          seen[key] = true
        end
        queue << row
      end
      @initial.rows.each(&enqueue)
      result = []
      until result.size == queue.size || (@limit && result.size >= @limit + @offset)
        row = queue[result.size]
        result << row
        @working.rows = [row]
        @recursive.rows.each(&enqueue)
      end
      Limits.window(result, @limit, @offset)
    end

    def correlated? = false

    def result_names = @initial.result_names

    def affinities = @initial.affinities
  end
end

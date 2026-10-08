# frozen_string_literal: true

require_relative "ast"
require_relative "binder"
require_relative "errors"
require_relative "evaluator"
require_relative "identifier"
require_relative "scope"
require_relative "table"
require_relative "values"

module Sql
  # The FROM of one query (4.1): plans its sources and joins (all names are checked here, before any
  # row is read) and produces the joined rows.
  #
  # A joined row has the values of every source side by side, in FROM order (the sources not joined
  # yet are NULL while joining), followed by the row of the enclosing query. Query works on these rows.
  class FromClause
    # What to read for one source: a Table, or a planned Query (a subquery in FROM, never correlated).
    Input = Data.define(:table, :query)
    # How the source at `index` is joined to the sources before it; `on` is bound (USING becomes an ON).
    Step = Data.define(:index, :kind, :on)

    # The scope that sees every source (the unqualified and `q.*` names of the query's other clauses).
    attr_reader :scope

    # from: a From or nil (no FROM: one empty row); parent: the Scope of the enclosing query, or nil.
    def initialize(from, planner, parent)
      items = from ? [from.first, *from.joins.map(&:item)] : []
      @inputs = []
      @sources = []
      @width = 0
      items.each { |item| add_source(item, planner) }
      correlation = Correlation.new
      @hidden = []
      @base = Scope.new(sources: @sources, width: @width, parent: parent, planner: planner, correlation: correlation)
      @steps = plan_steps(from, correlation)
      @scope = @base.with(hidden: @hidden)
      @materialized = {}
    end

    # Can the rows differ between two runs of one statement: does the FROM (an ON) use a name of the
    # enclosing query, or read a recursive cte's working table?
    def volatile?
      @scope.correlated? || @inputs.any? { |i| i.table.respond_to?(:volatile?) && i.table.volatile? }
    end

    # The joined rows; `outer_row` is the enclosing query's row ([] for a statement's own query).
    def rows(outer_row)
      rows = [Array.new(@width) + outer_row]
      @steps.each { |step| rows = join(rows, step) }
      rows
    end

    private

    def add_source(item, planner)
      input, name, columns, rowid =
        case item
        when TableRef then table_source(item, planner)
        else
          query = planner.plan(item.select, nil)
          [Input.new(nil, query), item.alias, query.result_columns]
        end
      @inputs << input
      @sources << Source.new(name, columns, @width, rowid || false)
      @width += columns.length
    end

    # A name in FROM is a table (to read its rows), or a view / cte (a planned query to run).
    def table_source(item, planner)
      target = planner.resolve(item.name)
      name = item.alias || item.name
      if target.is_a?(Table)
        [Input.new(target, nil), name, Source.of_table(name, target, @width).columns, true]
      elsif target.respond_to?(:rows)
        [Input.new(target, nil), name, target.columns.map { |c| SourceColumn.new(c.name, c.type) }]
      else
        [Input.new(nil, target), name, target.result_columns]
      end
    end

    def plan_steps(from, correlation)
      return [] unless from
      steps = [Step.new(0, :cross, nil)]
      from.joins.each_with_index do |join, i|
        index = i + 1
        on = join.using ? using_condition(index, join.using) : join.on
        on &&= Binder.bind(on, @base.with(sources: @sources.first(index + 1), hidden: @hidden.dup))
        steps << Step.new(index, join.kind, on)
      end
      steps
    end

    # `USING (c, ...)` is `A.c = B.c AND ...`: A.c from the first earlier source with a column c, B.c
    # from this source (whose copy of c is then left out of `*` and of unqualified names).
    def using_condition(index, names)
      right = @sources[index]
      conditions = names.map do |name|
        right_i = column_position(right, name)
        left = @sources.first(index).find { |s| column_position(s, name) }
        unless right_i && left
          raise SqlError, "cannot join using column #{name} - column not present in both tables"
        end
        @hidden << right.offset + right_i
        Binary.new(:eq, column_ref(left, column_position(left, name)), column_ref(right, right_i))
      end
      conditions.reduce { |all, c| Binary.new(:and, all, c) }
    end

    def column_ref(source, i)
      ColumnRef.new(source.offset + i, source.columns[i].type)
    end

    def column_position(source, name)
      source.columns.index { |c| c.name && Sql.fold(c.name) == Sql.fold(name) }
    end

    def source_rows(index)
      input = @inputs[index]
      input.table ? input.table.rows : (@materialized[index] ||= input.query.run([]))
    end

    # Extends each row of `rows` by the rows of the step's source that satisfy its ON; a LEFT JOIN
    # keeps a row without a partner, as it is (NULLs there).
    def join(rows, step)
      offset = @sources[step.index].offset
      candidates = source_rows(step.index)
      joined = []
      rows.each do |left|
        row = left.dup
        matched = false
        candidates.each do |candidate|
          row[offset, candidate.length] = candidate
          next if step.on && !Values.truth(Evaluator.evaluate(step.on, row))
          matched = true
          joined << row.dup
        end
        joined << left if step.kind == :left && !matched
      end
      joined
    end
  end
end

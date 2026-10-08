# frozen_string_literal: true

require_relative 'ast'
require_relative 'compiler'
require_relative 'errors'
require_relative 'namespace'
require_relative 'scope'
require_relative 'values'

module SQL
  # The FROM clause of one query (SPEC 4.1): resolves its sources and join constraints when built
  # (so name errors come before any row is read), and `rows` gives the joined rows.
  # A joined row is the columns of every source, in order, as one flat array.
  class FromClause
    Item = Struct.new(:source, :rows) # `rows` is a lambda giving the source's current rows
    Step = Struct.new(:kind, :item, :condition) # kind :cross :inner :left; condition nil or a lambda on a joined row

    # The Level of the whole clause, for the query's other clauses.
    attr_reader :level

    # `parent` is the Scope of the enclosing clause, `correlation` the flag of the query's Level.
    def initialize(ast, namespace, parent, correlation)
      @namespace = namespace
      @parent = parent
      @correlation = correlation
      @sources = []
      @first = nil
      @steps = []
      build(ast)
      @level = level_for(@sources)
    end

    def rows
      @steps.reduce(@first.rows.call) do |left_rows, step|
        join(left_rows, step, step.item.source.columns.size)
      end
    end

    private

    def level_for(sources) = Level.new(sources, @namespace, parent: @parent, correlation: @correlation)

    # Joins associate to the left, so the right side of a Join is always a single from-item.
    def build(node)
      if node.is_a?(Join)
        build(node.left)
        left_sources = @sources.dup
        item = add_item(node.right)
        @steps << Step.new(node.kind, item, join_condition(node, left_sources, item.source))
      else
        @first = add_item(node)
      end
    end

    def add_item(node)
      offset = @sources.sum { |s| s.columns.size }
      item =
        case node
        when TableSource
          relation = @namespace.relation(node.name)
          Item.new(Source.new(node.alias || relation.name, relation_columns(relation), offset), relation.rows)
        when SubquerySource
          relation = Relation.from_query(node.alias, QueryPlanner.plan(node.select, @namespace))
          Item.new(Source.new(node.alias, relation_columns(relation), offset), relation.rows)
        end
      @sources << item.source
      item
    end

    # Copies, as USING marks columns hidden in a Source.
    def relation_columns(relation) = relation.columns.map(&:dup)

    def join_condition(node, left_sources, right)
      if node.on
        compiler = Compiler.new(Scope.new(level_for(@sources)))
        fn = compiler.compile(node.on).fn
        ->(row) { Values.truth(fn.call(row)) == true }
      elsif node.using
        using_condition(node.using, left_sources, right)
      end
    end

    # USING (c, ...) is `left.c = right.c AND ...`; the left column is the first source's that has c.
    def using_condition(names, left_sources, right)
      pairs = names.map do |name|
        left = left_sources.find { |s| s.find(name) }
        ri = right.find(name)
        unless left && ri
          raise SqlError, "cannot join using column #{name} - column not present in both tables"
        end

        li = left.find(name)
        [left.offset + li, left.columns[li].affinity, right.offset + ri, right.columns[ri].affinity,
         left.columns[li].collation.name] # `left.c = right.c`: the left column's collation wins (7.4)
      end
      names.each { |name| right.columns[right.find(name)].hidden = true }
      lambda do |row|
        pairs.all? { |li, laff, ri, raff, coll| Values.compare(row[li], laff, row[ri], raff, coll) == 0 }
      end
    end

    def join(left_rows, step, right_width)
      right_rows = step.item.rows.call
      condition = step.condition
      left_rows.flat_map do |left|
        matched = right_rows.filter_map do |right|
          row = left + right
          row if condition.nil? || condition.call(row)
        end
        matched.empty? && step.kind == :left ? [left + Array.new(right_width)] : matched
      end
    end
  end
end

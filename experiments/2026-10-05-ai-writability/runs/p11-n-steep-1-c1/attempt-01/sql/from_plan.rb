# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "namespace"
require_relative "resolver"
require_relative "scope"
require_relative "table"

module Sql
  # One checked FROM item and the Source that names its columns. Its rows come from a stored
  # table, from a plan (a subquery, view or WITH table; planned by Planner, required by query.rb)
  # or from the feed of a recursive WITH table's recursive part: exactly one of the three is set.
  class PlanSource
    attr_reader :source, :table, :plan, :feed

    def initialize(source, table: nil, plan: nil, feed: nil)
      @source = source
      @table = table
      @plan = plan
      @feed = feed
    end
  end

  # A join of one more source onto those before it. kind is :cross, :inner or :left; condition is
  # the ON expression (or the one USING stands for), resolved against the sources up to this one.
  class PlanJoin
    attr_reader :kind, :item, :condition

    def initialize(kind, item, condition)
      @kind = kind
      @item = item
      @condition = condition
    end
  end

  # A checked FROM clause. first is nil for a SELECT without FROM; scope holds all its sources.
  class FromPlan
    attr_reader :first, :joins, :scope

    def initialize(first, joins, scope)
      @first = first
      @joins = joins
      @scope = scope
    end

    # The sources in FROM order.
    def items
      first = @first
      first ? [first] + @joins.map(&:item) : []
    end

    # Checks the FROM clause (nil: none); base is the scope of the query, with no sources yet.
    def self.build(clause, base)
      return new(nil, [], base) unless clause

      first = plan_item(clause.first, base)
      scope = base.with_source(first.source)
      joins = [] #: Array[PlanJoin]
      clause.joins.each do |join|
        item, scope, condition = plan_join(join, scope)
        joins << PlanJoin.new(join.kind, item, condition)
      end
      new(first, joins, scope)
    end

    # A table's (or view's or WITH table's) source is called by its alias, else its name as
    # written; a subquery's by its alias.
    def self.plan_item(item, scope)
      case item
      when Ast::TableSource then plan_named(item, scope)
      when Ast::SubquerySource
        plan = Planner.build(item.select, scope.namespace, nil)
        plan_of_plan(item.alias_name, plan.result_names, plan, scope)
      else raise Error, "internal error: unknown FROM item"
      end
    end
    private_class_method :plan_item

    # A name in FROM: a WITH table, else a view, else a stored table.
    def self.plan_named(item, scope)
      label = item.alias_name || item.table
      namespace = scope.namespace
      found = namespace.lookup(item.table)
      case found
      when Cte
        plan = Planner.plan_cte(found)
        names = declared_names(found.column_names, plan, "table #{found.name} has #{plan.column_count} values for " \
                                                          "#{found.column_names&.length} columns")
        return plan_of_plan(label, names, plan, scope)
      when WorkingTable
        names = found.column_names
        types = Array.new(names.length, nil) #: Array[column_type?]
        collations = Array.new(names.length, :binary) #: Array[collation]
        return PlanSource.new(Source.new(label, names, types, collations, scope.width, Array.new(names.length, false)),
                              feed: found.feed)
      end
      view = namespace.catalog.view(item.table)
      if view
        plan = Planner.plan_view(view, namespace.catalog)
        names = declared_names(view.column_names, plan, "expected #{view.column_names&.length} columns for " \
                                                       "'#{view.name}' but got #{plan.column_count}")
        return plan_of_plan(label, names, plan, scope)
      end
      table = namespace.catalog.fetch(item.table)
      names = table.columns.map(&:name) #: Array[String?]
      types = table.columns.map(&:type) #: Array[column_type?]
      collations = table.columns.map(&:collation)
      PlanSource.new(Source.new(label, names, types, collations, scope.width, Array.new(names.length, false)), table: table)
    end
    private_class_method :plan_named

    # The column names a view or WITH table gives its plan's columns: its list, else the plan's own.
    def self.declared_names(declared, plan, mismatch)
      return plan.result_names unless declared
      raise Error, mismatch if declared.length != plan.column_count

      declared #: Array[String?]
    end
    private_class_method :declared_names

    # A source whose rows are those of a plan; its columns keep the plan's affinities and take the
    # collations of its result columns (spec 7.5).
    def self.plan_of_plan(label, names, plan, scope)
      source = Source.new(label, names, plan.result_types, plan.result_collations, scope.width, Array.new(names.length, false))
      PlanSource.new(source, plan: plan)
    end
    private_class_method :plan_of_plan

    # The item of a join, the scope with it added, and its condition (nil: none).
    def self.plan_join(join, scope)
      using = join.using
      return plan_using(join.item, using, scope) if using

      item = plan_item(join.item, scope)
      wider = scope.with_source(item.source)
      on = join.on
      [item, wider, on ? Resolver.new(wider, {}).resolve(on) : nil]
    end
    private_class_method :plan_join

    # USING (c, ...) is c = c for each name: the first source before that has c, and the new one.
    def self.plan_using(from_item, names, scope)
      probe = plan_item(from_item, scope)
      right = probe.source
      condition = nil #: Ast::Expr?
      merged = Array.new(right.width, false)
      names.each do |name|
        position = right.position_of(name)
        left = scope.find_first(name)
        unless position && left
          raise Error, "cannot join using column #{name} - column not present in both tables"
        end

        merged[position] = true
        equal = Ast::Binary.new("=", Ast::ResolvedColumn.new(left.index, left.type, left.collation),
                                Ast::ResolvedColumn.new(right.offset + position, right.types.fetch(position),
                                                        right.collations.fetch(position)))
        previous = condition
        condition = previous ? Ast::Binary.new("AND", previous, equal) : equal
      end
      item = PlanSource.new(Source.new(right.name, right.names, right.types, right.collations, right.offset, merged),
                            table: probe.table, plan: probe.plan, feed: probe.feed)
      [item, scope.with_source(item.source), condition]
    end
    private_class_method :plan_using
  end
end

# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "resolver"
require_relative "scope"
require_relative "table"

module Sql
  # One checked FROM item: a stored table or a subquery (planned with SelectPlan, required by
  # query.rb), and the Source that names its columns.
  class PlanSource
    attr_reader :table, :plan, :source

    def initialize(table, plan, source)
      @table = table
      @plan = plan
      @source = source
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

    # A table's source is called by its alias, else its table name; a subquery's by its alias.
    def self.plan_item(item, scope)
      case item
      when Ast::TableSource
        table = scope.catalog.fetch(item.table)
        names = table.columns.map(&:name) #: Array[String?]
        types = table.columns.map(&:type) #: Array[column_type?]
        source = Source.new(item.alias_name || item.table, names, types, scope.width, Array.new(names.length, false))
        PlanSource.new(table, nil, source)
      when Ast::SubquerySource
        plan = SelectPlan.build(item.select, scope.catalog, nil)
        names = plan.result_names
        source = Source.new(item.alias_name, names, plan.result_types, scope.width, Array.new(names.length, false))
        PlanSource.new(nil, plan, source)
      else raise Error, "internal error: unknown FROM item"
      end
    end
    private_class_method :plan_item

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
        equal = Ast::Binary.new("=", Ast::ResolvedColumn.new(left.index, left.type),
                                Ast::ResolvedColumn.new(right.offset + position, right.types.fetch(position)))
        previous = condition
        condition = previous ? Ast::Binary.new("AND", previous, equal) : equal
      end
      item = PlanSource.new(probe.table, probe.plan, Source.new(right.name, right.names, right.types, right.offset, merged))
      [item, scope.with_source(item.source), condition]
    end
    private_class_method :plan_using
  end
end

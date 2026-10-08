# frozen_string_literal: true

require_relative "ast"
require_relative "call_slots"
require_relative "collation"
require_relative "error"
require_relative "evaluator"
require_relative "from_plan"
require_relative "plan"
require_relative "resolver"
require_relative "scope"
require_relative "window_defs"

module Sql
  # A SELECT with every name checked: result expressions, WHERE, GROUP BY terms, HAVING, ORDER BY
  # terms (positions and aliases already replaced by the expressions they stand for) and
  # LIMIT/OFFSET. The rows its expressions read are those of the FROM sources followed by the row
  # of the enclosing query (outer_width columns; none for a top-level query). In a grouped plan
  # (an aggregate query) the expressions after WHERE are resolved against group rows: those
  # width columns, then the value of each of slots (aggregate calls and window calls, in order;
  # the window calls are computed once the rows are final: see Windows).
  class SelectPlan < Plan
    attr_reader :distinct, :from, :results, :result_names, :where, :group_by, :having, :order_by,
                :limit, :offset, :slots, :aggregates, :windows, :width, :local_width, :outer_width

    # namespace finds the tables, views and WITH tables; parent is the scope of the enclosing
    # query, nil at the top level and for a subquery in FROM.
    def self.build(select, namespace, parent)
      from = FromPlan.build(select.from, Scope.new(namespace, [], parent))
      scope = from.scope
      slots = CallSlots.new(scope.full_width, WindowDefs.new(select.windows))
      aliases = {} #: Hash[String, Ast::Expr]
      names = [] #: Array[String?]
      results = resolve_results(select.items, scope, aliases, names, slots)
      grouped = !select.group_by.empty? || !slots.aggregates.empty?
      raise Error, "HAVING clause on a non-aggregate query" if select.having && !grouped

      where_expr = select.where
      where = where_expr ? Resolver.new(scope, aliases, :where).resolve(where_expr) : nil
      grouping = Resolver.new(scope, aliases, :group_by)
      group_by = select.group_by.each_with_index.map { |term, i| plan_group_term(term, i, results, grouping) }
      having_expr = select.having
      having = having_expr ? Resolver.new(scope, aliases, :having, slots).resolve(having_expr) : nil
      ordering = Resolver.new(scope, aliases, grouped ? :allow : :order, slots)
      order_by = select.order_by.each_with_index.map { |term, i| plan_term(term, i, results, aliases, ordering) }
      constants = Resolver.new(Scope.new(namespace, [], nil), {})
      limit = select.limit
      offset = select.offset
      new(distinct: select.distinct, from: from, results: results, result_names: names, where: where,
          group_by: group_by, having: having, order_by: order_by,
          limit: limit ? constants.resolve(limit) : nil, offset: offset ? constants.resolve(offset) : nil,
          grouped: grouped, slots: slots, width: slots.width, local_width: scope.width,
          outer_width: scope.outer_width)
    end

    # The result column expressions; fills aliases with those that have an AS name and names with
    # each column's name (nil if it has none).
    def self.resolve_results(items, scope, aliases, names, slots)
      results = [] #: Array[Ast::Expr]
      resolver = Resolver.new(scope, aliases, :allow, slots)
      items.each do |item|
        item_expr = item.expr
        if item_expr
          resolved = resolver.resolve(item_expr)
          results << resolved
          alias_name = item.alias_name
          aliases[Names.fold(alias_name)] = resolved if alias_name
          names << (alias_name || (item_expr.is_a?(Ast::ColumnRef) ? item_expr.name : nil))
        else
          qualifier = item.qualifier
          raise Error, "no tables specified" if qualifier.nil? && scope.sources.empty?

          star = scope.star_columns(qualifier) || raise(Error, "no such table: #{qualifier}")
          star.each do |location|
            results << Ast::ResolvedColumn.new(location.index, location.type, location.collation)
            names << location.name
          end
        end
      end
      results
    end

    # A term naming a result column by number may be followed by COLLATE (spec 7.4).
    def self.plan_group_term(expr, index, results, scope)
      collate = expr.is_a?(Ast::Collate) ? expr : nil
      position = literal_position(collate ? collate.operand : expr)
      return scope.resolve(expr) unless position

      unless position >= 1 && position <= results.length
        raise Error, "#{ordinal(index + 1)} GROUP BY term out of range - should be between 1 and #{results.length}"
      end

      resolved = results.fetch(position - 1)
      window = resolved.first_window
      raise Error, "misuse of window function #{window.name}()" if window
      raise Error, "aggregate functions are not allowed in the GROUP BY clause" if resolved.first_aggregate

      collate ? Ast::Collated.new(resolved, Collation.fetch(collate.name)) : resolved
    end

    # A term naming a result column by number or alias may be followed by COLLATE (spec 7.4).
    def self.plan_term(term, index, results, aliases, scope)
      expr = term.expr
      collate = expr.is_a?(Ast::Collate) ? expr : nil
      named = collate ? collate.operand : expr
      position = literal_position(named)
      if position
        unless position >= 1 && position <= results.length
          raise Error, "#{ordinal(index + 1)} ORDER BY term out of range - should be between 1 and #{results.length}"
        end

        resolved = results.fetch(position - 1)
      elsif named.is_a?(Ast::ColumnRef) && named.qualifier.nil? && aliases.key?(Names.fold(named.name))
        resolved = aliases.fetch(Names.fold(named.name))
      else
        return Ast::OrderTerm.new(scope.resolve(expr), term.descending, term.nulls_first)
      end
      resolved = Ast::Collated.new(resolved, Collation.fetch(collate.name)) if collate
      Ast::OrderTerm.new(resolved, term.descending, term.nulls_first)
    end

    # k for an integer literal k or -k, else nil.
    def self.literal_position(expr)
      if expr.is_a?(Ast::Literal)
        value = expr.value
        value.is_a?(Integer) ? value : nil
      elsif expr.is_a?(Ast::Unary) && expr.op == "-"
        inner = literal_position(expr.operand)
        inner && expr.operand.is_a?(Ast::Literal) ? -inner : nil
      end
    end

    def self.ordinal(n)
      suffix =
        if (11..13).cover?(n % 100) then "th"
        else
          case n % 10
          when 1 then "st"
          when 2 then "nd"
          when 3 then "rd"
          else "th"
          end
        end
      "#{n}#{suffix}"
    end

    # grouped tells that the query is an aggregate query (its aggregates may still be empty).
    def initialize(distinct:, from:, results:, result_names:, where:, group_by:, having:, order_by:,
                   limit:, offset:, grouped:, slots:, width:, local_width:, outer_width:)
      @distinct = distinct
      @from = from
      @results = results
      @result_names = result_names
      @where = where
      @group_by = group_by
      @having = having
      @order_by = order_by
      @limit = limit
      @offset = offset
      @slots = slots.all
      @aggregates = slots.aggregates
      @windows = slots.windows
      @grouped = grouped
      @width = width
      @local_width = local_width
      @outer_width = outer_width
    end

    def column_count
      @results.length
    end

    # The affinity of each result column: its column's type if it is a plain column reference.
    def result_types
      @results.map { |expr| expr.is_a?(Ast::ResolvedColumn) ? expr.type : nil }
    end

    # The collation of each result column (nil: none) and whether COLLATE gave it (spec 7.3).
    def result_collations
      @results.map(&:collation)
    end

    def result_explicit
      @results.map(&:explicit_collation?)
    end

    # Whether this is an aggregate query (has GROUP BY or aggregate calls in its result columns).
    def grouped?
      @grouped
    end
  end
end

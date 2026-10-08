# frozen_string_literal: true

require_relative "ast"
require_relative "errors"

module Sql
  # Parsing of selects: WITH, compound selects, FROM, ORDER BY (1.7, 3.1, 4.1, 5.1, 5.2). Mixed into Parser.
  module QueryParser
    private

    def query_start?
      kw?("SELECT") || kw?("WITH")
    end

    # [WITH ...] select-body (5.1, 5.2). `with` is a WITH clause already read, if any.
    def parse_query(with = nil)
      with ||= parse_with_clause if kw?("WITH")
      body = parse_select_body
      with ? WithQuery.new(with[0], with[1], body) : body
    end

    # WITH [RECURSIVE] cte, ... -> [recursive, ctes]
    def parse_with_clause
      expect_kw("WITH")
      recursive = !accept_kw("RECURSIVE").nil?
      ctes = [parse_cte]
      ctes << parse_cte while accept_op(",")
      [recursive, ctes]
    end

    def parse_cte
      name = expect_ident
      columns = op?("(") ? parse_name_list : nil
      expect_kw("AS")
      expect_op("(")
      select = parse_query
      expect_op(")")
      Cte.new(name, columns, select)
    end

    # simple-select [compound-op simple-select]... [ORDER BY ...] [LIMIT ...]: a Select, or a Compound.
    def parse_select_body
      first = parse_select
      rest = []
      while (op = accept_compound_operator)
        rest << [op, parse_select]
      end
      order_by = accept_order_by_clause
      limit = offset = nil
      if accept_kw("LIMIT")
        limit = parse_expr
        offset = parse_expr if accept_kw("OFFSET")
      end
      return first.with(order_by: order_by, limit: limit, offset: offset) if rest.empty?
      Compound.new(first, rest, order_by, limit, offset)
    end

    # UNION [ALL] | INTERSECT | EXCEPT -> :union :union_all :intersect :except; nil if none.
    def accept_compound_operator
      if accept_kw("UNION") then accept_kw("ALL") ? :union_all : :union
      elsif accept_kw("INTERSECT") then :intersect
      elsif accept_kw("EXCEPT") then :except
      end
    end

    # A simple-select: no ORDER BY / LIMIT (those belong to parse_select_body).
    def parse_select
      expect_kw("SELECT")
      distinct = !accept_kw("DISTINCT").nil?
      accept_kw("ALL") unless distinct
      columns = [parse_result_column]
      columns << parse_result_column while accept_op(",")
      from = accept_kw("FROM") ? parse_from : nil
      where = accept_kw("WHERE") ? parse_expr : nil
      group_by = accept_group_by_clause
      having = accept_kw("HAVING") ? parse_expr : nil
      Select.new(distinct, columns, from, where, group_by, having, [], nil, nil)
    end

    # from-item [join-op from-item [join-constraint]]...  (4.1)
    def parse_from
      first = parse_from_item
      joins = []
      loop do
        kind = accept_join_operator or break
        item = parse_from_item
        on, using = parse_join_constraint(kind)
        joins << JoinStep.new(kind, item, on, using)
      end
      From.new(first, joins)
    end

    # `,` | CROSS JOIN | [INNER] JOIN | LEFT [OUTER] JOIN -> :cross :cross :inner :left; nil if none.
    def accept_join_operator
      if accept_op(",") then :cross
      elsif accept_kw("CROSS") then expect_kw("JOIN") && :cross
      elsif accept_kw("INNER") then expect_kw("JOIN") && :inner
      elsif accept_kw("LEFT")
        accept_kw("OUTER")
        expect_kw("JOIN") && :left
      elsif accept_kw("JOIN") then :inner
      end
    end

    # [ON expr | USING ( column, ... )] -> [on, using]; a LEFT JOIN needs one, a cross join takes none.
    def parse_join_constraint(kind)
      if kind != :cross && accept_kw("ON")
        [parse_expr, nil]
      elsif kind != :cross && accept_kw("USING")
        expect_op("(")
        columns = [expect_ident]
        columns << expect_ident while accept_op(",")
        expect_op(")")
        [nil, columns]
      else
        fail_syntax if kind == :left
        [nil, nil]
      end
    end

    def parse_from_item
      if accept_op("(")
        fail_syntax unless query_start?
        select = parse_query
        expect_op(")")
        SubqueryRef.new(select, accept_alias)
      else
        TableRef.new(expect_ident, accept_alias)
      end
    end

    # [AS] name, or nil
    def accept_alias
      if accept_kw("AS") then expect_ident
      elsif peek.type == :ident then advance.value
      end
    end

    # GROUP BY expr, ... (nil when absent)
    def accept_group_by_clause
      return nil unless accept_kw("GROUP")
      expect_kw("BY")
      parse_expression_list
    end

    # ORDER BY term, ... ([] when absent)
    def accept_order_by_clause
      return [] unless accept_kw("ORDER")
      expect_kw("BY")
      terms = [parse_order_term]
      terms << parse_order_term while accept_op(",")
      terms
    end

    def parse_result_column
      return ResultColumn.new(Star.new, nil) if accept_op("*")
      return ResultColumn.new(parse_table_star, nil) if table_star?
      ResultColumn.new(parse_expr, accept_alias)
    end

    # At `name . *`
    def table_star?
      dot = @tokens[@pos + 1]
      star = @tokens[@pos + 2]
      peek.type == :ident && dot&.type == :op && dot.value == "." && star&.type == :op && star.value == "*"
    end

    def parse_table_star
      name = advance.value
      2.times { advance }
      TableStar.new(name)
    end

    def parse_order_term
      expr = parse_expr
      desc = false
      if accept_kw("DESC")
        desc = true
      else
        accept_kw("ASC")
      end
      nulls = nil
      if accept_kw("NULLS")
        nulls = if accept_kw("FIRST") then :first
                else
                  expect_kw("LAST")
                  :last
                end
      end
      OrderTerm.new(expr, desc, nulls)
    end
  end
end

# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "lexer"
require_relative "value"

module Sql
  # Recursive-descent parser for one statement's tokens (as produced by Lexer).
  class Parser
    def initialize(tokens)
      @tokens = tokens
      @pos = 0
    end

    # The statement, or nil for an empty one.
    def parse_statement
      return nil if peek.kind == :eof

      statement =
        if accept_keyword("CREATE") then create_table
        elsif accept_keyword("DROP") then drop_table
        elsif accept_keyword("INSERT") then insert
        elsif accept_keyword("SELECT") then select
        elsif accept_keyword("UPDATE") then update
        elsif accept_keyword("DELETE") then delete
        else syntax_error
        end
      syntax_error unless peek.kind == :eof
      statement
    end

    private

    def syntax_error
      raise Error, "syntax error"
    end

    def peek
      @tokens.fetch(@pos)
    end

    # The token n places after the next one (the :eof token when there is none).
    def peek_ahead(n)
      @tokens.fetch([@pos + n, @tokens.length - 1].min)
    end

    def advance
      token = peek
      @pos += 1 if token.kind != :eof
      token
    end

    def accept_keyword(word)
      return false unless peek.keyword?(word)

      advance
      true
    end

    def expect_keyword(word)
      syntax_error unless accept_keyword(word)
    end

    def accept_op(symbol)
      return false unless peek.op?(symbol)

      advance
      true
    end

    def expect_op(symbol)
      syntax_error unless accept_op(symbol)
    end

    def name
      syntax_error unless peek.kind == :ident
      advance.text
    end

    # CREATE TABLE [IF NOT EXISTS] name ( column-def, ... )
    def create_table
      expect_keyword("TABLE")
      if_not_exists = false
      if accept_keyword("IF")
        expect_keyword("NOT")
        expect_keyword("EXISTS")
        if_not_exists = true
      end
      table = name
      expect_op("(")
      columns = [column_def]
      constraints = [] #: Array[Ast::TableConstraint]
      while accept_op(",")
        if peek.keyword?("PRIMARY") || peek.keyword?("UNIQUE")
          constraints << table_constraint
        else
          syntax_error unless constraints.empty?
          columns << column_def
        end
      end
      expect_op(")")
      Ast::CreateTable.new(table, columns, constraints, if_not_exists)
    end

    # name type [PRIMARY KEY | NOT NULL | UNIQUE | DEFAULT value]...
    def column_def
      column = name
      type = column_type(name) || syntax_error
      not_null = false
      unique = false
      primary_key = false
      default_value = nil #: value
      loop do
        if accept_keyword("PRIMARY")
          expect_keyword("KEY")
          primary_key = true
        elsif accept_keyword("NOT")
          expect_keyword("NULL")
          not_null = true
        elsif accept_keyword("UNIQUE")
          unique = true
        elsif accept_keyword("DEFAULT")
          default_value = default_literal
        else
          break
        end
      end
      Ast::ColumnDef.new(name: column, type: type, not_null: not_null, unique: unique,
                         primary_key: primary_key, default_value: default_value)
    end

    # [+ | -] numeric-literal | string-literal | NULL
    def default_literal
      return nil if accept_keyword("NULL")

      negative = accept_op("-")
      positive = !negative && accept_op("+")
      token = advance
      case token.kind
      when :number
        number = Value.parse_number(token.text)
        negative ? -number : number
      when :string
        syntax_error if negative || positive
        token.text
      else syntax_error
      end
    end

    # PRIMARY KEY (column, ...) | UNIQUE (column, ...)
    def table_constraint
      primary_key = accept_keyword("PRIMARY")
      expect_keyword(primary_key ? "KEY" : "UNIQUE")
      expect_op("(")
      names = [name]
      names << name while accept_op(",")
      expect_op(")")
      Ast::TableConstraint.new(primary_key, names)
    end

    def column_type(word)
      case word.upcase
      when "INTEGER" then :integer
      when "REAL" then :real
      when "TEXT" then :text
      end
    end

    def drop_table
      expect_keyword("TABLE")
      if_exists = false
      if accept_keyword("IF")
        expect_keyword("EXISTS")
        if_exists = true
      end
      Ast::DropTable.new(name, if_exists)
    end

    def insert
      expect_keyword("INTO")
      table = name
      columns = nil #: Array[String]?
      if accept_op("(")
        names = [name]
        names << name while accept_op(",")
        expect_op(")")
        columns = names
      end
      expect_keyword("VALUES")
      rows = [value_row]
      rows << value_row while accept_op(",")
      Ast::Insert.new(table, columns, rows)
    end

    def value_row
      expect_op("(")
      row = [expression]
      row << expression while accept_op(",")
      expect_op(")")
      row
    end

    # SELECT [DISTINCT | ALL] items [FROM sources] [WHERE e] [GROUP BY e, ...] [HAVING e]
    # [ORDER BY ...] [LIMIT e [OFFSET e]] (the SELECT is already consumed)
    def select
      distinct = accept_keyword("DISTINCT")
      accept_keyword("ALL") unless distinct
      items = [select_item]
      items << select_item while accept_op(",")
      from = accept_keyword("FROM") ? from_clause : nil
      where = accept_keyword("WHERE") ? expression : nil
      group_by = accept_keyword("GROUP") ? expression_list_after_by : [] #: Array[Ast::Expr]
      having = accept_keyword("HAVING") ? expression : nil
      order_by = accept_keyword("ORDER") ? order_terms : [] #: Array[Ast::OrderTerm]
      limit = nil #: Ast::Expr?
      offset = nil #: Ast::Expr?
      if accept_keyword("LIMIT")
        limit = expression
        offset = expression if accept_keyword("OFFSET")
      end
      Ast::Select.new(distinct, items, from, where, group_by, having, order_by, limit, offset)
    end

    # from-item [join-op from-item [ON expr | USING ( column, ... )]]...
    def from_clause
      first = from_item
      joins = [] #: Array[Ast::Join]
      loop do
        if accept_op(",")
          joins << Ast::Join.new(:cross, from_item, nil, nil)
        elsif accept_keyword("CROSS")
          expect_keyword("JOIN")
          joins << Ast::Join.new(:cross, from_item, nil, nil)
        elsif accept_keyword("LEFT")
          accept_keyword("OUTER")
          expect_keyword("JOIN")
          joins << join_with_constraint(:left, true)
        elsif accept_keyword("INNER")
          expect_keyword("JOIN")
          joins << join_with_constraint(:inner, false)
        elsif accept_keyword("JOIN")
          joins << join_with_constraint(:inner, false)
        else
          break
        end
      end
      Ast::FromClause.new(first, joins)
    end

    # The item after a JOIN and its constraint; a JOIN without one is a cross join unless required.
    def join_with_constraint(kind, required)
      item = from_item
      if accept_keyword("ON")
        Ast::Join.new(kind, item, expression, nil)
      elsif accept_keyword("USING")
        expect_op("(")
        names = [name]
        names << name while accept_op(",")
        expect_op(")")
        Ast::Join.new(kind, item, nil, names)
      else
        syntax_error if required
        Ast::Join.new(:cross, item, nil, nil)
      end
    end

    # table [[AS] alias] | ( select ) [[AS] alias]
    def from_item
      if accept_op("(")
        expect_keyword("SELECT")
        inner = select
        expect_op(")")
        Ast::SubquerySource.new(inner, optional_alias)
      else
        table = name
        Ast::TableSource.new(table, optional_alias)
      end
    end

    def optional_alias
      if accept_keyword("AS")
        name
      elsif peek.kind == :ident
        name
      end
    end

    # BY expr, expr, ...
    def expression_list_after_by
      expect_keyword("BY")
      list = [expression]
      list << expression while accept_op(",")
      list
    end

    # UPDATE table SET column = expr, ... [WHERE expr]
    def update
      table = name
      expect_keyword("SET")
      assignments = [assignment]
      assignments << assignment while accept_op(",")
      where = accept_keyword("WHERE") ? expression : nil
      Ast::Update.new(table, assignments, where)
    end

    def assignment
      column = name
      expect_op("=")
      Ast::Assignment.new(column, expression)
    end

    # DELETE FROM table [WHERE expr]
    def delete
      expect_keyword("FROM")
      table = name
      where = accept_keyword("WHERE") ? expression : nil
      Ast::Delete.new(table, where)
    end

    def select_item
      return Ast::SelectItem.new(nil, nil, nil) if accept_op("*")

      if peek.kind == :ident && peek_ahead(1).op?(".") && peek_ahead(2).op?("*")
        qualifier = name
        advance
        advance
        return Ast::SelectItem.new(nil, nil, qualifier)
      end
      Ast::SelectItem.new(expression, optional_alias, nil)
    end

    def order_terms
      expect_keyword("BY")
      terms = [order_term]
      terms << order_term while accept_op(",")
      terms
    end

    def order_term
      expr = expression
      descending = false
      if accept_keyword("DESC")
        descending = true
      else
        accept_keyword("ASC")
      end
      nulls_first = nil #: bool?
      if accept_keyword("NULLS")
        if accept_keyword("FIRST")
          nulls_first = true
        else
          expect_keyword("LAST")
          nulls_first = false
        end
      end
      Ast::OrderTerm.new(expr, descending, nulls_first)
    end

    # Expressions, loosest binding first: OR, AND, NOT, equality/IS/IN/LIKE/BETWEEN, comparison,
    # + -, * / %, ||, unary.
    def expression
      left = conjunction
      left = Ast::Binary.new("OR", left, conjunction) while accept_keyword("OR")
      left
    end

    def conjunction
      left = negation
      left = Ast::Binary.new("AND", left, negation) while accept_keyword("AND")
      left
    end

    def negation
      return Ast::Unary.new("NOT", negation) if accept_keyword("NOT")

      equality
    end

    def equality
      left = comparison
      loop do
        if peek.keyword?("IS")
          advance
          negated = accept_keyword("NOT")
          left = Ast::Is.new(left, comparison, negated)
        elsif peek.kind == :op && %w[= == != <>].include?(peek.text)
          op = advance.text
          left = Ast::Binary.new(op == "==" ? "=" : (op == "<>" ? "!=" : op), left, comparison)
        elsif (test = membership_test(left))
          left = test
        else
          return left
        end
      end
    end

    # [NOT] IN (...), [NOT] LIKE p or [NOT] BETWEEN a AND b after left; nil (consuming nothing)
    # when the next tokens are none of these.
    def membership_test(left)
      negated = peek.keyword?("NOT")
      word = negated ? peek_ahead(1) : peek
      return nil unless word.keyword?("IN") || word.keyword?("LIKE") || word.keyword?("BETWEEN")

      advance if negated
      advance
      if word.keyword?("IN")
        expect_op("(")
        if accept_keyword("SELECT")
          inner = select
          expect_op(")")
          return Ast::InSubquery.new(left, inner, negated)
        end
        candidates = [expression]
        candidates << expression while accept_op(",")
        expect_op(")")
        Ast::InList.new(left, candidates, negated)
      elsif word.keyword?("LIKE")
        Ast::Like.new(left, comparison, negated)
      else
        low = comparison
        expect_keyword("AND")
        Ast::Between.new(left, low, comparison, negated)
      end
    end

    def comparison
      left = additive
      while peek.kind == :op && %w[< <= > >=].include?(peek.text)
        op = advance.text
        left = Ast::Binary.new(op, left, additive)
      end
      left
    end

    def additive
      left = multiplicative
      while peek.kind == :op && %w[+ -].include?(peek.text)
        op = advance.text
        left = Ast::Binary.new(op, left, multiplicative)
      end
      left
    end

    def multiplicative
      left = concatenation
      while peek.kind == :op && %w[* / %].include?(peek.text)
        op = advance.text
        left = Ast::Binary.new(op, left, concatenation)
      end
      left
    end

    def concatenation
      left = unary
      left = Ast::Binary.new("||", left, unary) while accept_op("||")
      left
    end

    def unary
      return Ast::Unary.new("-", unary) if accept_op("-")
      return Ast::Unary.new("+", unary) if accept_op("+")

      primary
    end

    def primary
      token = advance
      case token.kind
      when :number then Ast::Literal.new(token.text.match?(/[.eE]/) ? Float(token.text) : Integer(token.text, 10))
      when :string then Ast::Literal.new(token.text)
      when :keyword then keyword_primary(token)
      when :ident then identifier_primary(token.text)
      when :op
        syntax_error unless token.text == "("
        parenthesized
      else syntax_error
      end
    end

    # A function call, a qualified column or a column; the name is already consumed.
    def identifier_primary(word)
      if peek.op?("(")
        function_call(word)
      elsif accept_op(".")
        Ast::ColumnRef.new(name, word)
      else
        Ast::ColumnRef.new(word, nil)
      end
    end

    # The rest of "( expr )" or "( select )" (the "(" is already consumed).
    def parenthesized
      if accept_keyword("SELECT")
        inner = select
        expect_op(")")
        return Ast::ScalarSubquery.new(inner)
      end
      inner = expression
      expect_op(")")
      inner
    end

    def keyword_primary(token)
      case token.text
      when "EXISTS" then exists_expression      when "NULL" then Ast::Literal.new(nil)
      when "CASE" then case_expression
      when "CAST" then cast_expression
      else syntax_error
      end
    end

    # EXISTS ( select ) (the EXISTS is already consumed)
    def exists_expression
      expect_op("(")
      expect_keyword("SELECT")
      inner = select
      expect_op(")")
      Ast::ExistsSubquery.new(inner)
    end

    # CASE [subject] WHEN c THEN r [WHEN ...] [ELSE e] END (the CASE is already consumed)
    def case_expression
      subject = peek.keyword?("WHEN") ? nil : expression
      whens = [] #: Array[Ast::WhenClause]
      begin
        expect_keyword("WHEN")
        condition = expression
        expect_keyword("THEN")
        whens << Ast::WhenClause.new(condition, expression)
      end while peek.keyword?("WHEN")
      else_result = accept_keyword("ELSE") ? expression : nil
      expect_keyword("END")
      Ast::CaseExpr.new(subject, whens, else_result)
    end

    # CAST ( expr AS type ) (the CAST is already consumed)
    def cast_expression
      expect_op("(")
      operand = expression
      expect_keyword("AS")
      type = column_type(name) || syntax_error
      expect_op(")")
      Ast::Cast.new(operand, type)
    end

    # name ( [DISTINCT] expr, ... [ORDER BY terms] ) or name ( * ); the name is already consumed.
    def function_call(function)
      expect_op("(")
      args = [] #: Array[Ast::Expr]
      star = false
      distinct = false
      order_by = [] #: Array[Ast::OrderTerm]
      if accept_op("*")
        star = true
      elsif !peek.op?(")")
        distinct = accept_keyword("DISTINCT")
        args << expression
        args << expression while accept_op(",")
        order_by = order_terms if accept_keyword("ORDER")
      end
      expect_op(")")
      Ast::FunctionCall.new(function, args, distinct: distinct, star: star, order_by: order_by)
    end
  end
end

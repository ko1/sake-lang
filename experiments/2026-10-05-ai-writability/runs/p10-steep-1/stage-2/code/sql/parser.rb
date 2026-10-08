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

    # The token after the next one (the :eof token when there is none).
    def peek_second
      @tokens.fetch([@pos + 1, @tokens.length - 1].min)
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

    def select
      items = [select_item]
      items << select_item while accept_op(",")
      table = accept_keyword("FROM") ? name : nil
      where = accept_keyword("WHERE") ? expression : nil
      order_by = accept_keyword("ORDER") ? order_terms : [] #: Array[Ast::OrderTerm]
      limit = nil #: Ast::Expr?
      offset = nil #: Ast::Expr?
      if accept_keyword("LIMIT")
        limit = expression
        offset = expression if accept_keyword("OFFSET")
      end
      Ast::Select.new(items, table, where, order_by, limit, offset)
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
      return Ast::SelectItem.new(nil, nil) if accept_op("*")

      expr = expression
      alias_name = nil #: String?
      if accept_keyword("AS")
        alias_name = name
      elsif peek.kind == :ident
        alias_name = name
      end
      Ast::SelectItem.new(expr, alias_name)
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
      word = negated ? peek_second : peek
      return nil unless word.keyword?("IN") || word.keyword?("LIKE") || word.keyword?("BETWEEN")

      advance if negated
      advance
      if word.keyword?("IN")
        expect_op("(")
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
      when :ident then peek.op?("(") ? function_call(token.text) : Ast::ColumnRef.new(token.text)
      when :op
        syntax_error unless token.text == "("
        inner = expression
        expect_op(")")
        inner
      else syntax_error
      end
    end

    def keyword_primary(token)
      case token.text
      when "NULL" then Ast::Literal.new(nil)
      when "CASE" then case_expression
      when "CAST" then cast_expression
      else syntax_error
      end
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

    def function_call(function)
      expect_op("(")
      args = [] #: Array[Ast::Expr]
      unless accept_op(")")
        args << expression
        args << expression while accept_op(",")
        expect_op(")")
      end
      Ast::FunctionCall.new(function, args)
    end
  end
end

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
      columns << column_def while accept_op(",")
      expect_op(")")
      Ast::CreateTable.new(table, columns, if_not_exists)
    end

    def column_def
      column = name
      type_word = name
      type = column_type(type_word)
      syntax_error unless type
      Ast::ColumnDef.new(column, type)
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

    # Expressions, loosest binding first: OR, AND, NOT, equality/IS, comparison, + -, * / %, ||, unary.
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
        else
          return left
        end
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
      when :keyword
        syntax_error unless token.text == "NULL"
        Ast::Literal.new(nil)
      when :ident then peek.op?("(") ? function_call(token.text) : Ast::ColumnRef.new(token.text)
      when :op
        syntax_error unless token.text == "("
        inner = expression
        expect_op(")")
        inner
      else syntax_error
      end
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

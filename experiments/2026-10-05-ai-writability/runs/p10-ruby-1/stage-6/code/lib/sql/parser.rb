# frozen_string_literal: true

require_relative "ast"
require_relative "errors"
require_relative "identifier"
require_relative "expression_parser"
require_relative "lexer"
require_relative "query_parser"
require_relative "schema_parser"
require_relative "window_parser"

module Sql
  # Recursive-descent parser: the tokens of ONE statement -> a statement node (ast.rb).
  # Only grammar is checked here; names, types and counts are checked later. The grammar is split
  # over SchemaParser (DDL, transactions), QueryParser (selects) and ExpressionParser; this class has
  # the token helpers and the statements that are small (INSERT, UPDATE, DELETE).
  class Parser
    include SchemaParser
    include QueryParser
    include ExpressionParser
    include WindowParser

    EOF_TOKEN = Token.new(:eof, nil)

    def self.parse(tokens)
      new(tokens).parse_statement
    end

    def initialize(tokens)
      @tokens = tokens
      @pos = 0
    end

    def parse_statement
      statement =
        if kw?("SELECT") then parse_query
        elsif kw?("WITH") then parse_with_statement
        elsif accept_kw("INSERT") then parse_insert(nil)
        elsif accept_kw("CREATE") then parse_create
        elsif accept_kw("DROP") then parse_drop
        elsif accept_kw("ALTER") then parse_alter
        elsif accept_kw("UPDATE") then parse_update
        elsif accept_kw("DELETE") then parse_delete
        elsif accept_kw("BEGIN") then parse_transaction_end(Begin)
        elsif accept_kw("COMMIT") || accept_kw("END") then parse_transaction_end(Commit)
        elsif accept_kw("ROLLBACK") then parse_transaction_end(Rollback)
        else fail_syntax
        end
      fail_syntax unless peek.type == :eof
      statement
    end

    private

    # ---- token helpers ----

    def peek
      @tokens[@pos] || EOF_TOKEN
    end

    def advance
      token = peek
      @pos += 1
      token
    end

    def fail_syntax
      raise SyntaxError
    end

    def kw?(word)
      t = peek
      t.type == :kw && t.value == word
    end

    def op?(text)
      t = peek
      t.type == :op && t.value == text
    end

    def accept_kw(word)
      kw?(word) ? advance : nil
    end

    def accept_op(text)
      op?(text) ? advance : nil
    end

    def expect_kw(word)
      accept_kw(word) || fail_syntax
    end

    def expect_op(text)
      accept_op(text) || fail_syntax
    end

    def expect_ident
      peek.type == :ident ? advance.value : fail_syntax
    end

    # ---- statements ----

    def parse_update
      table = expect_ident
      expect_kw("SET")
      assignments = [parse_assignment]
      assignments << parse_assignment while accept_op(",")
      where = accept_kw("WHERE") ? parse_expr : nil
      Update.new(table, assignments, where)
    end

    def parse_assignment
      column = expect_ident
      expect_op("=")
      [column, parse_expr]
    end

    def parse_delete
      expect_kw("FROM")
      table = expect_ident
      where = accept_kw("WHERE") ? parse_expr : nil
      Delete.new(table, where)
    end

    # `WITH ... INSERT` or `WITH ... select`
    def parse_with_statement
      with = parse_with_clause
      accept_kw("INSERT") ? parse_insert(with) : parse_query(with)
    end

    # `with`: the WITH clause that came before the INSERT, or nil.
    def parse_insert(with)
      expect_kw("INTO")
      table = expect_ident
      columns = op?("(") ? parse_name_list : nil
      if accept_kw("VALUES")
        fail_syntax if with
        rows = [parse_value_row]
        rows << parse_value_row while accept_op(",")
        Insert.new(table, columns, rows, nil)
      else
        Insert.new(table, columns, nil, parse_query(with))
      end
    end

    def parse_value_row
      expect_op("(")
      row = parse_expression_list
      expect_op(")")
      row
    end

    def parse_expression_list
      list = [parse_expr]
      list << parse_expr while accept_op(",")
      list
    end
  end
end

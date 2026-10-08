# frozen_string_literal: true

require_relative "ast"
require_relative "errors"

module Sql
  # Parsing of CREATE / DROP / ALTER and transaction statements (2.1, 5.3 - 5.7). Mixed into Parser.
  module SchemaParser
    private

    def parse_create
      if accept_kw("TABLE") then parse_create_table
      elsif accept_kw("VIEW") then parse_create_view
      elsif accept_kw("UNIQUE") then expect_kw("INDEX") && parse_create_index(true)
      elsif accept_kw("INDEX") then parse_create_index(false)
      else fail_syntax
      end
    end

    # [IF NOT EXISTS]
    def accept_if_not_exists
      return false unless accept_kw("IF")
      expect_kw("NOT")
      expect_kw("EXISTS")
      true
    end

    # [IF EXISTS]
    def accept_if_exists
      return false unless accept_kw("IF")
      expect_kw("EXISTS")
      true
    end

    # ( name, ... )
    def parse_name_list
      expect_op("(")
      names = [expect_ident]
      names << expect_ident while accept_op(",")
      expect_op(")")
      names
    end

    def parse_create_table
      if_not_exists = accept_if_not_exists
      name = expect_ident
      expect_op("(")
      columns = [parse_column_def]
      constraints = []
      while accept_op(",")
        if kw?("PRIMARY") || kw?("UNIQUE")
          constraints << parse_table_constraint
        else
          fail_syntax unless constraints.empty? # column definitions come before table constraints
          columns << parse_column_def
        end
      end
      expect_op(")")
      CreateTable.new(name, columns, if_not_exists, constraints)
    end

    def parse_column_def
      name = expect_ident
      type = Sql.fold(expect_ident)
      fail_syntax unless Sql::COLUMN_TYPES.include?(type)
      flags = { primary_key: false, not_null: false, unique: false }
      default = nil
      collation = nil
      loop do
        if accept_kw("PRIMARY")
          expect_kw("KEY")
          flags[:primary_key] = true
        elsif accept_kw("NOT")
          expect_kw("NULL")
          flags[:not_null] = true
        elsif accept_kw("UNIQUE")
          flags[:unique] = true
        elsif accept_kw("DEFAULT")
          default = Default.new(parse_default_value)
        elsif accept_kw("COLLATE")
          collation = expect_ident
        else
          break
        end
      end
      ColumnDef.new(name, type.to_sym, flags[:primary_key], flags[:not_null], flags[:unique], default, collation)
    end

    # [+ | -] numeric-literal | string-literal | NULL
    def parse_default_value
      return nil if accept_kw("NULL")
      return advance.value if peek.type == :str
      negative = accept_op("-")
      accept_op("+") unless negative
      fail_syntax unless %i[int float].include?(peek.type)
      negative ? -advance.value : advance.value
    end

    def parse_table_constraint
      kind = if accept_kw("PRIMARY")
               expect_kw("KEY")
               :primary_key
             else
               expect_kw("UNIQUE")
               :unique
             end
      TableConstraint.new(kind, parse_name_list)
    end

    def parse_drop
      kind = if accept_kw("TABLE") then DropTable
             elsif accept_kw("VIEW") then DropView
             else
               expect_kw("INDEX")
               DropIndex
             end
      if_exists = accept_if_exists
      kind.new(expect_ident, if_exists)
    end

    def parse_create_view
      if_not_exists = accept_if_not_exists
      name = expect_ident
      columns = op?("(") ? parse_name_list : nil
      expect_kw("AS")
      CreateView.new(name, columns, parse_query, if_not_exists)
    end

    def parse_create_index(unique)
      if_not_exists = accept_if_not_exists
      name = expect_ident
      expect_kw("ON")
      table = expect_ident
      names, collations = parse_indexed_columns
      CreateIndex.new(name, table, names, unique, if_not_exists, collations)
    end

    # ( column [COLLATE name], ... ) -> [names, collation names (nil where none)]
    def parse_indexed_columns
      expect_op("(")
      names = []
      collations = []
      loop do
        names << expect_ident
        collations << (accept_kw("COLLATE") ? expect_ident : nil)
        break unless accept_op(",")
      end
      expect_op(")")
      [names, collations]
    end

    def parse_alter
      expect_kw("TABLE")
      table = expect_ident
      if accept_kw("ADD")
        accept_kw("COLUMN")
        AlterAddColumn.new(table, parse_column_def)
      else
        expect_kw("RENAME")
        return AlterRenameTable.new(table, expect_ident) if accept_kw("TO")
        accept_kw("COLUMN")
        column = expect_ident
        expect_kw("TO")
        AlterRenameColumn.new(table, column, expect_ident)
      end
    end

    # The optional TRANSACTION after BEGIN / COMMIT / END / ROLLBACK.
    def parse_transaction_end(node)
      accept_kw("TRANSACTION")
      node.new
    end
  end
end

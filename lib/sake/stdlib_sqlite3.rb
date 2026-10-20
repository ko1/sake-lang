# frozen_string_literal: true

module Sake
  module Stdlib
    module_function

    SQLITE3_DB = "SQLite3::Database"
    SQLITE3_STMT = "SQLite3::Statement"
    # The gem's exception classes (SQLite3::Exception and its subclasses), rescuable by these names.
    SQLITE3_EXCEPTIONS = %w[SQLException ConstraintException BusyException LockedException ReadOnlyException
                            MisuseException RangeException MismatchException CantOpenException NotADatabaseException
                            IOException FullException TooBigException AbortException InterruptException
                            PermissionException CorruptException InternalException MemoryException NotFoundException
                            ProtocolException EmptyException SchemaChangedException AuthorizationException
                            FormatException UnsupportedException].map { "SQLite3::#{_1}" }.freeze
    SQLITE3_BIND_TYPES = %w[Integer Float String Nil].freeze

    # SQLite3::Database: Ruby's sqlite3 gem, its rows as Arrays of Integer, Float, String (TEXT and BLOB) and nil.
    def install_sqlite3(reg)
      reg.define(SQLITE3_DB, :new, ["String"]) { |path| sqlite3_error { require "sqlite3"; ::SQLite3::Database.new(path) } }
      reg.define(SQLITE3_DB, :execute, [SQLITE3_DB, "String"], optional: ["Array"]) do |db, sql, binds = []|
        sqlite3_error { sqlite3_rows(db.execute(sql, sqlite3_binds(binds))) }
      end
      reg.define(SQLITE3_DB, :execute2, [SQLITE3_DB, "String"], optional: ["Array"]) do |db, sql, binds = []|
        sqlite3_error { sqlite3_rows(db.execute2(sql, sqlite3_binds(binds))) }
      end
      reg.define(SQLITE3_DB, :execute_batch, [SQLITE3_DB, "String"]) { |db, sql| sqlite3_error { db.execute_batch(sql) }.then { nil } }
      reg.define(SQLITE3_DB, :last_insert_row_id, [SQLITE3_DB]) { |db| sqlite3_error { db.last_insert_row_id } }
      reg.define(SQLITE3_DB, :changes, [SQLITE3_DB]) { |db| sqlite3_error { db.changes } }
      reg.define(SQLITE3_DB, :close, [SQLITE3_DB]) { |db| sqlite3_error { db.close unless db.closed? }.then { nil } }
      reg.define(SQLITE3_DB, :closed?, [SQLITE3_DB], &:closed?)
      reg.define(SQLITE3_DB, :total_changes, [SQLITE3_DB]) { |db| sqlite3_error { db.total_changes } }
      # transaction(db) { |db| }: the block's value, committed; an error in the block rolls back and is raised again.
      # break, next, return and throw leave it committed, as the gem's ensure does.
      reg.define(SQLITE3_DB, :transaction, [SQLITE3_DB], block: :required) do |db, &b|
        sqlite3_error { db.transaction }
        aborted = false
        begin
          b.call(db)
        rescue Interpreter::JumpSignal, Interpreter::ReturnSignal
          raise
        rescue ::Exception
          aborted = true
          db.rollback if db.transaction_active?
          raise
        ensure
          sqlite3_error { db.commit } if !aborted && db.transaction_active?
        end
      end
      install_sqlite3_statement(reg)
    end

    # SQLite3::Statement: a prepared statement (the gem's), as ActiveRecord's adapter uses it.
    def install_sqlite3_statement(reg)
      st = SQLITE3_STMT
      prepare = ->(db, sql) { sqlite3_error { db.prepare(sql) } }
      reg.define(SQLITE3_DB, :prepare, [SQLITE3_DB, "String"], &prepare)
      reg.define(st, :new, [SQLITE3_DB, "String"], &prepare)
      reg.define(st, :bind_params, [st, "Array"]) { |s, binds| sqlite3_error { s.bind_params(sqlite3_binds(binds)) }.then { s } }
      reg.define(st, :step, [st]) { |s| sqlite3_error { s.step }&.then { sqlite3_rows([_1])[0] } }
      reg.define(st, :to_a, [st]) { |s| sqlite3_error { sqlite3_rows(s.to_a) } }
      # execute(stmt, binds): reset, bound, run; the rows (the gem gives a ResultSet of them).
      reg.define(st, :execute, [st], optional: ["Array"]) { |s, binds = []| sqlite3_error { sqlite3_rows(s.execute(sqlite3_binds(binds)).to_a) } }
      reg.define(st, :reset!, [st]) { |s| sqlite3_error { s.reset! }.then { s } }
      reg.define(st, :columns, [st]) { |s| sqlite3_error { s.columns.map(&:dup) } }
      reg.define(st, :types, [st]) { |s| sqlite3_error { s.types.map { _1&.dup } } }
      reg.define(st, :column_count, [st]) { |s| sqlite3_error { s.column_count } }
      reg.define(st, :done?, [st]) { |s| sqlite3_error { s.done? } }
      reg.define(st, :close, [st]) { |s| sqlite3_error { s.close unless s.closed? }.then { nil } }
      reg.define(st, :closed?, [st], &:closed?)
    end

    def sqlite3_binds(binds)
      binds.each_with_index do |v, i|
        next if v.nil? || v.is_a?(Integer) || v.is_a?(Float) || v.is_a?(String)
        raise Fail.new("TypeError", "can't prepare #{Values.type_of(v)} (bind #{i + 1}; give Integer, Float, String or nil)")
      end
    end

    # Column names come frozen from the gem; a Sake String is not.
    def sqlite3_rows(rows) = rows.map { |r| r.map { _1.is_a?(String) && _1.frozen? ? _1.dup : _1 } }

    def sqlite3_error
      yield
    rescue LoadError => e
      raise Fail.new("IOError", "sqlite3 is not available here (#{e.message})")
    rescue ::StandardError => e
      raise unless defined?(::SQLite3::Exception) && e.is_a?(::SQLite3::Exception)
      name = e.class.name
      raise Fail.new(SQLITE3_EXCEPTIONS.include?(name) ? name : "SQLite3::Exception", e.message)
    end
  end
end

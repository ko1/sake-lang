# frozen_string_literal: true

module Sake
  module Stdlib
    module_function

    SQLITE3_DB = "SQLite3::Database"
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
      # transaction(db) { |db| }: the block's value, committed; an error in the block rolls back and is raised again.
      reg.define(SQLITE3_DB, :transaction, [SQLITE3_DB], block: :required) do |db, &b|
        sqlite3_error { db.transaction }
        begin
          v = b.call(db)
        rescue Interpreter::JumpSignal, Interpreter::ReturnSignal # break, next, return: committed, as in Ruby
          sqlite3_error { db.commit } if db.transaction_active?
          raise
        rescue ::Exception
          db.rollback if db.transaction_active?
          raise
        end
        sqlite3_error { db.commit } if db.transaction_active?
        v
      end
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

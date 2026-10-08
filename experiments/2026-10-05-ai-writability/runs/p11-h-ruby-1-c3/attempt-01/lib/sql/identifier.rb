# frozen_string_literal: true

module Sql
  # Names are case-insensitive for ASCII letters only; `fold` is the key to compare and store them by.
  # Error messages use the spelling the statement wrote, so keep the original beside the folded key.
  def self.fold(name)
    name.downcase(:ascii)
  end

  ROWID_NAMES = %w[rowid _rowid_ oid].freeze

  # Is `name` one of the names of a table's hidden rowid (7.1)? Real columns of that name win elsewhere.
  def self.rowid_name?(name)
    ROWID_NAMES.include?(fold(name))
  end
end

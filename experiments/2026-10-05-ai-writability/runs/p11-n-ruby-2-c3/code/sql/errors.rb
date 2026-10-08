# frozen_string_literal: true

module SQL
  # An error reported to the script as `Error: <message>`; the statement has no effect.
  class SqlError < StandardError
    def self.syntax = new('syntax error')
  end
end

# frozen_string_literal: true

module Sql
  # A SQL-level failure; its message is printed as "Error: <message>".
  class Error < StandardError
  end
end

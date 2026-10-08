# frozen_string_literal: true

module Sql
  # An error the script is told about as `Error: <message>`. The statement that raised it has no effect.
  class SqlError < StandardError; end

  class SyntaxError < SqlError
    def initialize(message = "syntax error")
      super
    end
  end
end

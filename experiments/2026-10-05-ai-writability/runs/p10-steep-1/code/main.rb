# frozen_string_literal: true

require_relative "sql/engine"

# Reads a SQL script from standard input and runs it; see SPEC.md.
Sql::Engine.new.run_script($stdin.read, $stdout)

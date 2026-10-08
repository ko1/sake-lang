# frozen_string_literal: true

# Usage: ruby main.rb < script.sql
# Runs a SQL script (a small subset of SQLite, see SPEC.md) against an in-memory database.

require_relative "lib/sql/script"

source = $stdin.binmode.read.force_encoding(Encoding::UTF_8)
$stdout.sync = false
begin
  Sql::Script.new.run(source) { |line| $stdout.puts(line) }
ensure
  $stdout.flush
end

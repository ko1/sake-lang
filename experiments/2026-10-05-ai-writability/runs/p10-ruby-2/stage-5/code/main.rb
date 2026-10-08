# frozen_string_literal: true

# Entry point: run the SQL script on standard input against an empty in-memory database.
require_relative 'sql/engine'

$stdin.set_encoding(Encoding::UTF_8)
$stdout.set_encoding(Encoding::UTF_8)
SQL::Engine.new($stdout).run_script($stdin.read)

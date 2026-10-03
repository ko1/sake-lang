# frozen_string_literal: true

# Level-1 reports split by the checker's verdict: "surely fails" (every type that reaches the
# operation fails it) or "may fail" (some do, some do not). Prints one JSON line per program.
# usage: ruby split.rb FILE.sake...
require "json"
require "stringio"
require_relative "../../lib/sake"
require_relative "../../lib/sake/typer"
require_relative "../../lib/sake/cli"

ARGV.each do |path|
  prog = Sake.load(File.read(path), path, out: StringIO.new, input: StringIO.new)
  typer = Sake::Typer.new(prog).run
  level1 = Sake::CLI::STRICT_LEVELS[1]
  rows = typer.findings.select { |_, item| level1.include?(item) }.map do |c, item|
    { item:, verdict: c.verdict.to_s, op: c.op, line: c.line }
  end
  puts JSON.generate(path:, reports: rows)
rescue Sake::StaticErrors, StandardError => e
  puts JSON.generate(path:, error: "#{e.class}: #{e.message[0, 120]}")
end

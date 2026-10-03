# frozen_string_literal: true

# B again, with Struct fields inferred per definition: a field whose every write is a value known
# without fields and elements (see field_writes.rb) keeps its type; other fields and every element
# stay unknown unless declared. Prints one JSON line per program: decided checks and rejections.
# usage: ruby struct_fields.rb FILE.sake...
require_relative "field_writes"
require_relative "../../lib/sake/cli"
require "set"

class PerDefinitionTyper < NoFixpointTyper
  def initialize(program, local_fields)
    super(program)
    @local_fields = local_fields
  end

  def data_op(dt, name, args, node)
    f = name.delete_prefix("get_")
    # Its own writes, collected in this typer (their values do not depend on fields or elements).
    return @fields[dt.name][f] || [] if name.start_with?("get_") && @local_fields.include?([dt.name, f])
    super
  end
end

def counts(t) = t.checks.values.map(&:verdict).tally.transform_keys(&:to_s)

ARGV.each do |path|
  prog = Sake.load(File.read(path), path, out: StringIO.new, input: StringIO.new)
  nofix = NoFixpointTyper.new(prog).run
  full = Sake::Typer.new(prog).run
  by_field = (nofix.writes || {}).group_by { |k, _| k[0, 2] }
  local = by_field.select { |_, ws| ws.all? { |_, vs| !vs.include?(:depends) } }.keys
  per = PerDefinitionTyper.new(prog, local.to_set).run
  rej = ->(t, l) { !Sake::CLI.strict_diagnostics(prog, Sake::CLI::STRICT_LEVELS[l], t).empty? }
  puts JSON.generate(path:, full: counts(full), nofix: counts(nofix), per: counts(per),
                     reject: { full: [rej.(full, 1), rej.(full, 2)], nofix: [rej.(nofix, 1), rej.(nofix, 2)], per: [rej.(per, 1), rej.(per, 2)] })
rescue StandardError => e
  puts JSON.generate(path:, error: "#{e.class}: #{e.message[0, 200]}")
end

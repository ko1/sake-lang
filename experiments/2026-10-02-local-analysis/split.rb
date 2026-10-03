# frozen_string_literal: true

# Which part of the whole-program fixpoint matters: fields or collection elements?
# Runs the typer with only fields unknown (unless declared), and with only elements unknown.
# usage: ruby split.rb FILE.sake...   (one JSON line per program)
require_relative "field_writes"
require_relative "../../lib/sake/cli"

class FieldsUnknown < Sake::Typer
  def data_op(dt, name, args, node)
    return (ft = dt.field_types[name.delete_prefix("get_")]) ? t(ft) : unknown("field") if name.start_with?("get_")
    super
  end
end

class ElementsUnknown < Sake::Typer
  def elem_of(ty)
    sites = array_sites(ty)
    return [] if sites.empty?
    decl = sites.map(&:declared)
    decl.all? && !decl.any? { STRUCTURED.include?(_1) } ? u(*decl.map { t(_1) }) : unknown("element")
  end
  def set_elem(ty) = atoms_of(ty, :set).empty? ? [] : unknown("element")
  def hash_kv(ty) = atoms_of(ty, :hash).empty? ? [[], []] : [unknown("key"), unknown("value")]
end

def counts(t) = t.checks.values.map(&:verdict).tally.transform_keys(&:to_s)

ARGV.each do |path|
  prog = Sake.load(File.read(path), path, out: StringIO.new, input: StringIO.new)
  puts JSON.generate(path:, fields_unknown: counts(FieldsUnknown.new(prog).run), elements_unknown: counts(ElementsUnknown.new(prog).run))
rescue StandardError => e
  puts JSON.generate(path:, error: "#{e.class}: #{e.message[0, 200]}")
end

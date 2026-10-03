# frozen_string_literal: true

# Can field types be inferred per Struct definition, without the whole-program fixpoint?
# A Struct names its fields, and every write is a typed operation (T.new, T.set_x, @x = v inside the
# class), so the write sites are known syntactically. A field's type is then the union of the values
# written there; it needs the fixpoint only when a written value depends on another field or an element.
# Measured with the typer of local.rb's B (fields and elements unknown unless declared): a write whose
# value type is still known does not depend on them. Prints one JSON line per program.
# usage: ruby field_writes.rb FILE.sake...
require "json"
require "stringio"
require_relative "../../lib/sake"
require_relative "../../lib/sake/typer"

# Types every program has (the built-in exception types), not the program's own.
BUILTIN_STRUCTS = Sake.load("", "empty.sake", out: StringIO.new, input: StringIO.new).struct_types.keys.freeze

class NoFixpointTyper < Sake::Typer
  attr_reader :writes

  def elem_of(ty)
    sites = array_sites(ty)
    return [] if sites.empty?
    decl = sites.map(&:declared)
    decl.all? && !decl.any? { STRUCTURED.include?(_1) } ? u(*decl.map { t(_1) }) : unknown("element")
  end

  def set_elem(ty) = atoms_of(ty, :set).empty? ? [] : unknown("element")
  def hash_kv(ty) = atoms_of(ty, :hash).empty? ? [[], []] : [unknown("key"), unknown("value")]

  def data_op(dt, name, args, node)
    if name.start_with?("get_")
      f = name.delete_prefix("get_")
      return (ft = dt.field_types[f]) ? t(ft) : unknown("field")
    end
    super
  end

  def field_write(dt, field, ty, node)
    key = [dt, field, node.location.start_line, node.location.start_column]
    ((@writes ||= {})[key] ||= []) << (unknown?(ty) ? :depends : :local) unless ty.empty?
    super
  end
end

if __FILE__ == $0
ARGV.each do |path|
  prog = Sake.load(File.read(path), path, out: StringIO.new, input: StringIO.new)
  t = NoFixpointTyper.new(prog).run
  sites = (t.writes || {}).transform_values { _1.include?(:depends) ? "depends" : "local" }
  fields = sites.group_by { |k, _| k[0, 2] }.transform_values { |ws| ws.all? { _2 == "local" } ? "local" : "depends" }
  user = prog.struct_types.keys - BUILTIN_STRUCTS
  declared = prog.struct_types.values_at(*user).sum { |dt| dt.fields.size }
  puts JSON.generate(path:, sites: sites.values.tally, fields: fields.values.tally, fields_declared: declared,
                     depends: sites.select { _2 == "depends" }.keys.map { |dt, f, l, _| "#{dt}.#{f} L#{l}" })
rescue StandardError => e
  puts JSON.generate(path:, error: "#{e.class}: #{e.message[0, 200]}")
end
end

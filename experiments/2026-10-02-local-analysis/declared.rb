# frozen_string_literal: true

# How many fields and Array allocation sites have a declared element/field type (T[...], class settings)?
# usage: ruby declared.rb FILE.sake...   (prints totals)
require "stringio"
require_relative "../../lib/sake"
require_relative "../../lib/sake/typer"

# Types every program has (the built-in exception types), not the program's own.
BUILTIN_STRUCTS = Sake.load("", "empty.sake", out: StringIO.new, input: StringIO.new).struct_types.keys.freeze
fields = fdecl = sites = sdecl = 0
ARGV.each do |path|
  prog = Sake.load(File.read(path), path, out: StringIO.new, input: StringIO.new)
  t = Sake::Typer.new(prog).run
  prog.struct_types.reject { |n, _| BUILTIN_STRUCTS.include?(n) }.each_value { |dt| fields += dt.fields.size; fdecl += dt.fields.count { dt.field_types[_1] } }
  t.sites.each_value { |s| sites += 1; sdecl += 1 if s.declared }
  hashes = t.send(:hash_sites).size
  sets = t.send(:set_sites).size
  (@hs ||= [0, 0]); @hs[0] += hashes; @hs[1] += sets
rescue StandardError => e
  warn "#{path}: #{e.class}"
end
puts "fields: #{fields}, with a declared type: #{fdecl}"
puts "Array sites: #{sites}, declared T[...]: #{sdecl}"
puts "Hash sites: #{@hs[0]}, Set sites: #{@hs[1]} (no element declarations exist for these)"

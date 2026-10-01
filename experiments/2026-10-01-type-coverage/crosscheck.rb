# frozen_string_literal: true

# Soundness check of the experimental typer: run each program, record the runtime type seen at every
# type-checked operation, and verify it is contained in the statically inferred type for that site.
# usage: ruby crosscheck.rb [--sabotage] FILE.sake...   (prints a Markdown table; exit 1 on any violation)
#   --no-narrow: disable nil narrowing on `if x` / `while x`.
#   --sabotage: negative control; makes the typer claim Integer for every arithmetic result,
#               so programs using Float must show violations if this check works.
require "stringio"
require_relative "../../lib/sake"
require_relative "../../lib/sake/typer"

module Recorder
  attr_accessor :observed, :result_types

  def call_builtin(fn, args, blk, node)
    # Arguments of the untyped constructors (Array[], Hash[], Set[]) and of Index.[] / []= are "Any": nothing is checked.
    unless %w[Array[] Hash[] Set[]].include?(fn.full_name) || fn.namespace == "Index"
      args.each_with_index do |a, i|
        next if fn.name != "[]" && fn.param_type(i) == "Any" # nothing to check (also internal setters of `@x = v`)
        # `T[...]` checks each element; the typer records those as arg "elem".
        arg = fn.name == "[]" ? "elem" : i + 1
        key = [node.location.start_line, node.location.start_column, fn.full_name, arg]
        (observed[key] ||= Set.new) << [Sake::Values.type_of(a)]
      end
    end
    r = super
    # The result type is checked too: every built-in has a hand-written result type in the typer.
    (result_types[node] ||= [fn.full_name, Set.new])[1] << Sake::Values.type_of(r)
    r
  end

  def binary_op(node, op, a, b)
    key = [node.location.start_line, node.location.start_column, "BinaryOp.#{op}", "pair"]
    (observed[key] ||= Set.new) << [Sake::Values.type_of(a), Sake::Values.type_of(b)]
    super
  end
end
Sake::Interpreter.prepend(Recorder)

if ARGV.delete("--sabotage")
  Sake::Typer.prepend(Module.new do
    def binop_result(op, t1, t2) = Sake::Typer::COMPARE_OPS.include?(op) || t1 == "String" ? super : t("Integer")
  end)
end

def atom_name(a)
  return (a == "IndexNil" ? "Nil" : a) if a.is_a?(String)
  return "{#{a[1].map { |f, ty| "#{f}: #{atom_name(ty.first)}" }.join(", ")}}" if a[0] == :record
  { tuple: "Tuple", array: "Array", unknown: "?", range: "Range", hash: "Hash", set: "Set" }.fetch(a[0])
end

# Static type of a check site as a set of name tuples comparable with the observations.
def static_names(check)
  if check.arg == "pair"
    check.actual.flat_map { |pair| pair[1][0].product(pair[1][1]).map { |x, y| [atom_name(x), atom_name(y)] } }.to_set
  else
    check.actual.map { [atom_name(_1)] }.to_set
  end
end

narrow = !ARGV.delete("--no-narrow")
violations = 0
puts "| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |"
puts "|---|---|---|---|---|---|---|---|---|"
ARGV.each do |path|
  out = StringIO.new
  program = Sake.load(File.read(path), path, out:)
  typer = Sake::Typer.new(program, narrow:).run
  static_by_loc = typer.checks.to_h { |k, c| [[k[0], k[1], k[2], k[3]], c] }

  interp = Sake::Interpreter.new(program) # the same nodes as the typer saw
  interp.observed = {}
  interp.result_types = {}.compare_by_identity
  begin
    interp.run
  rescue Sake::RunError
    nil # observations up to the failure still count
  end

  bad = []
  unchecked = 0
  interp.observed.each do |key, seen|
    c = static_by_loc[key]
    if c.nil?
      # "Any" parameters are not recorded statically; anything else missing means the typer never reached it.
      fn = program.registry.lookup(*key[2].split(".", 2)) if key[2].include?(".")
      want = fn&.param_type(key[3] - 1)
      next if want == "Any"
      unchecked += 1
      bad << "#{key.inspect}: observed #{seen.to_a.inspect} but no static check"
      next
    end
    names = static_names(c)
    next if names.include?(["?"]) || seen.subset?(names)
    bad << "L#{key[0]} #{key[2]} #{key[3]}: observed #{seen.to_a.inspect}, static #{typer.show(c.actual)}"
  end
  interp.result_types.each do |node, (name, seen)|
    static = typer.results[node]
    next if static.nil? || static.any? { _1.is_a?(Array) && _1[0] == :unknown }
    names = static.map { atom_name(_1) }.to_set
    next if seen.subset?(names)
    bad << "L#{node.location.start_line} #{name} result: observed #{seen.to_a.inspect}, static #{typer.show(static)}"
  end
  violations += bad.size
  s = typer.summary
  puts "| #{File.basename(path)} | #{typer.passes} | #{s[:proven]} | #{s[:partial]} | #{s[:error]} | #{s[:unknown]} | #{interp.observed.size} | #{unchecked} | #{bad.size} |"
  bad.each { warn "#{path}: #{_1}" }
end
exit(violations.zero? ? 0 : 1)

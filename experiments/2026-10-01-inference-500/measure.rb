# frozen_string_literal: true

# How much the Sake typer infers, per program. Prints one JSON object per program.
# usage: ruby measure.rb FILE.sake...
#
# Every inferred type is turned into a structural type (allocation sites dropped: Array@L3[Integer] and
# Array@L5[Integer] are both Array[Integer]) and classified, worst first:
#   unknown  the typer gave up at the top
#   partial  unknown somewhere inside (Array[?])
#   union    two or more non-nil types somewhere (Integer | Float, Array[Integer | String])
#   nilable  nil | T somewhere, otherwise single
#   mono     exactly one type, all the way down
#   none     no value reaches here (unreached code); not a classification of a type
#
# Measured units:
#   expr.var   each local/it/@field read node: union over every analysis of it (all instantiations)
#   expr.call  each call node (functions, built-ins, operators, indexing, yield), likewise
#   sig.param  each parameter of each reached user function, union over instantiations; the subject
#              (first parameter of a function in a Struct type's class, when it is that type) is skipped
#   sig.ret    the return type of each reached user function
#   sig.field  each field of each Struct type (union of every write)
require "json"
require "stringio"
require_relative "../../lib/sake"
require_relative "../../lib/sake/typer"
require_relative "classify"

module Measure
  attr_reader :rec, :fn_args, :fn_rets

  # The typer evaluates SakeAST; a Prism expression is measured at the SakeAST node that computes its
  # value (other nodes made from the same Prism node, such as the subject read of `@x`, do not count).
  CALLS = [Sake::AST::CallBuiltin, Sake::AST::CallUser, Sake::AST::CallDispatch, Sake::AST::CallUnion, Sake::AST::UnOp, Sake::AST::BinOp, Sake::AST::IsNil,
           Sake::AST::IndexGet, Sake::AST::IndexSet, Sake::AST::FieldGet, Sake::AST::FieldSet, Sake::AST::Raise,
           Sake::AST::ReRaise, Sake::AST::LVarGet].freeze

  def ev(node, env)
    reset_rec if @rec_pass != @passes
    r = super
    o = node.origin
    primary =
      case o
      when Prism::LocalVariableReadNode, Prism::ItLocalVariableReadNode then node.is_a?(Sake::AST::LVarGet)
      when Prism::InstanceVariableReadNode then node.is_a?(Sake::AST::FieldGet)
      when Prism::CallNode then CALLS.include?(node.class)
      when Prism::YieldNode then node.is_a?(Sake::AST::Yield)
      end
    @rec[o] = Sake::Typer.union(@rec[o] || [], r) if primary
    r
  end

  def call_user(fn, args, blk)
    reset_rec if @rec_pass != @passes
    r = super
    (@fn_args[fn] ||= Array.new(args.size) { [] }).each_index { |i| @fn_args[fn][i] = Sake::Typer.union(@fn_args[fn][i], args[i]) }
    @fn_rets[fn] = Sake::Typer.union(@fn_rets[fn] || [], r)
    r
  end

  # Only the last pass counts (the earlier ones see tables that are still growing).
  def reset_rec
    @rec_pass = @passes
    @rec = {}.compare_by_identity
    @fn_args = {}.compare_by_identity
    @fn_rets = {}.compare_by_identity
  end

  # Structural form: a frozen set of atoms, each a String or [kind, ...] with nested structural types.
  def structural(ty, seen = {})
    ty.map { |a| struct_atom(a, seen) }.uniq.sort_by(&:inspect)
  end

  def struct_atom(a, seen)
    return(a == "IndexNil" ? "Nil" : a) if a.is_a?(String)
    key = [a[0], a[1]]
    return [:rec] if seen[key] # a site that contains itself
    seen = seen.merge(key => true)
    case a[0]
    when :tuple then [:tuple, a[1].map { structural(_1, seen) }]
    when :record then [:record, a[1].map { |f, t| [f, structural(t, seen)] }]
    when :array then [:array, structural(sites.fetch(a[1]).elem, seen)]
    when :hash then s = hash_sites.fetch(a[1]); [:hash, structural(s.key, seen), structural(s.val, seen)]
    when :set then [:set, structural(set_sites.fetch(a[1]).elem, seen)]
    when :range then [:range, structural(a[1], seen)]
    when :unknown then [:unknown]
    else [a[0]]
    end
  end
end
Sake::Typer.prepend(Measure)


def walk(node, &blk)
  return unless node
  yield node
  node.compact_child_nodes.each { walk(_1, &blk) }
end

ARGV.each do |path|
  program = Sake.load(File.read(path), path, out: StringIO.new)
  typer = Sake::Typer.new(program).run
  all_fns = program.functions.values.flat_map(&:values)
  nodes = []
  seen_bodies = {}.compare_by_identity
  program.toplevel.each { |st| walk(st) { nodes << _1 } }
  all_fns.each do |fn|
    next if seen_bodies[fn.body]
    seen_bodies[fn.body] = true
    walk(fn.body) { nodes << _1 }
  end
  counts = Hash.new { |h, k| h[k] = Hash.new(0) }
  detail = []
  nodes.uniq(&:object_id).each do |n|
    unit =
      case n
      when Prism::LocalVariableReadNode, Prism::ItLocalVariableReadNode, Prism::InstanceVariableReadNode then "expr.var"
      when Prism::CallNode, Prism::YieldNode
        # `.T` in a chain `x.T.f(...)` is not an expression of its own.
        next if n.is_a?(Prism::CallNode) && n.receiver && n.name.to_s.match?(/\A[A-Z]/) && n.arguments.nil? && n.block.nil?
        "expr.call"
      end
    next unless unit
    ty = typer.rec[n]
    c = ty ? Classify.classify(typer.structural(ty)) : :none
    counts[unit][c] += 1
    detail << [unit, n.location.start_line, n.slice[0, 40], c, typer.show(ty)] unless %i[mono none].include?(c)
  end
  typer.fn_args.each do |fn, args|
    struct_ns = program.struct_types.key?(fn.namespace)
    args.each_with_index do |ty, i|
      next if i.zero? && struct_ns && ty == [fn.namespace]
      c = Classify.classify(typer.structural(ty))
      counts["sig.param"][c] += 1
      detail << ["sig.param", fn.node.location.start_line, "#{fn.full_name} #{fn.params[i]}", c, typer.show(ty)] unless c == :mono
    end
    c = Classify.classify(typer.structural(typer.fn_rets[fn]))
    counts["sig.ret"][c] += 1
    detail << ["sig.ret", fn.node.location.start_line, fn.full_name, c, typer.show(typer.fn_rets[fn])] unless c == :mono
  end
  typer.fields.each do |dt, fs|
    fs.each do |f, ty|
      c = Classify.classify(typer.structural(ty))
      counts["sig.field"][c] += 1
      detail << ["sig.field", 0, "#{dt}.#{f}", c, typer.show(ty)] unless c == :mono
    end
  end
  dead = typer.dead_functions.reject { _1.origin } # copies made by include are not functions the writer wrote
  puts JSON.generate(path:, passes: typer.passes, converged: typer.passes < Sake::Typer::MAX_PASSES,
                     dead: dead.map(&:full_name), counts:, checks: typer.summary, detail:)
rescue StandardError, SystemStackError => e
  puts JSON.generate(path:, error: "#{e.class}: #{e.message.lines.first&.chomp}")
end

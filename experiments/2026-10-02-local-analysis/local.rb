# frozen_string_literal: true

# How much of Sake's checking needs whole-program analysis? Two measurements per program (JSON lines).
# usage: ruby local.rb FILE.sake...
#
# A. Parameter requirements, derived from each function's body alone. Every function is analyzed by
#    itself with each parameter an opaque value ([:unknown, "param", key, excluded]); the operations
#    applied to it (a built-in's parameter type, an operator's table rows, indexing, a Struct getter,
#    a module's dispatch, a call to another function with it) narrow the set of types it may be.
#    `x in T`, `case x in T` and nil checks exclude types on their paths. Classified per parameter:
#    one (a single type), union (2+ types), any (no requirement), none (no type works).
#    Soundness of the instrument: every type a parameter really gets when the program runs must be in
#    its requirement (the programs are correct); violations are counted and listed.
# B. Dependence on fields and collection elements. The whole-program typer is run again with every
#    field read and every Array/Hash/Set element unknown unless declared (a field type, T[...]); the
#    checks that stay decided (proven/error/partial) and the level-1/2 rejections are compared.
require "json"
require "set"
require "stringio"
require_relative "../../lib/sake"
require_relative "../../lib/sake/typer"
require_relative "../../lib/sake/cli"

BUILTIN_TYPES = %w[Integer Float Rational Complex String Symbol Boolean Nil Array Hash Set Range Tuple Time Regexp MatchData Record].freeze

# --- A ---

class LocalTyper < Sake::Typer
  attr_reader :req

  def param_atom(key) = [:unknown, "param", key, [].freeze].freeze
  def param?(a) = a.is_a?(Array) && a[0] == :unknown && a[1] == "param"
  def universe = @universe ||= (BUILTIN_TYPES + @program.struct_types.keys).to_set

  # x may be one of wants (or of the types already ruled out on this path).
  # Only while the parameter's own function is analyzed: a parameter written into a field or an element
  # (shared by the whole program) and read back elsewhere is not that function's requirement.
  def constrain(a, wants)
    return if wants.include?("Any") || a[2][0] != @root
    names = wants.map { _1.start_with?("{") ? "Record" : _1 }.map { _1 == "IndexNil" ? "Nil" : _1 }
    (@req ||= {})[a[2]] = (@req[a[2]] || universe) & (names.to_set | a[3].to_set)
    ((@why ||= {})[a[2]] ||= []) << "#{caller_locations(1, 1).first.label} L#{@node_line} #{names.first(6).join("|")}" if ENV["WHY"]
  end

  attr_reader :why

  def ev(node, env)
    @node_line = node.origin.location.start_line if ENV["WHY"] && node.origin.respond_to?(:location)
    super
  end

  def record(node, op, arg, want, actual)
    actual.each { |a| constrain(a, Array(want)) if param?(a) } unless want == "Any"
    super
  end

  # The elements of a parameter (when it is a collection) are as unknown as the parameter.
  def elem_of(ty) = ty.any? { param?(_1) } ? u(super, unknown("param element")) : super
  def set_elem(ty) = ty.any? { param?(_1) } ? u(super, unknown("param element")) : super
  def range_elem(ty) = ty.any? { param?(_1) } ? u(super, unknown("param element")) : super
  def hash_kv(ty) = ty.any? { param?(_1) } ? super.map { u(_1, unknown("param element")) } : super

  def structs_including(mod) = @program.struct_types.keys.select { Sake::Operators.includes?(@program.includes || {}, _1, mod) }

  def binop(node, op, a, b)
    op = op.to_s
    unless %w[== !=].include?(op)
      rows = @registry.binary_ops[op].keys
      mod = Sake::Operators::MODULE_OF.fetch(op)
      if a.any? { param?(_1) } && !b.empty? && !b.any? { param?(_1) } && !unknown?(b)
        rights = b.map { atom_type_name(_1) }
        ok = rows.select { |l, r| rights.include?(r) }.map(&:first) + structs_including(mod)
        a.each { constrain(_1, ok) if param?(_1) }
      end
      if b.any? { param?(_1) } && !a.empty? && !a.any? { param?(_1) } && !unknown?(a)
        lefts = a.map { atom_type_name(_1) }
        ok = rows.select { |l, r| lefts.include?(l) }.map(&:last)
        ok = BUILTIN_TYPES + @program.struct_types.keys if a.any? { struct_atom?(_1) } # a user operator takes anything
        b.each { constrain(_1, ok) if param?(_1) }
      end
    end
    super
  end

  def unop(node, op, a)
    ok = @registry.unary_ops[op].keys + structs_including(Sake::Operators::MODULE_OF.fetch(op))
    a.each { constrain(_1, ok) if param?(_1) }
    super
  end

  INDEXABLE = %w[String Array Tuple Hash MatchData].freeze

  def index_get(node, recv, key, lit, extra = nil)
    recv.each { constrain(_1, INDEXABLE + structs_including("Indexable")) if param?(_1) }
    super
  end

  def index_set(node, recv, key, lit, val, extra = nil)
    recv.each { constrain(_1, %w[Array Tuple Hash] + structs_including("Indexable")) if param?(_1) }
    super
  end

  # On the path where `x in T` (or `case x in T`) holds, x is a T; elsewhere it is not.
  def match_atoms(ty, pat)
    params = ty.select { param?(_1) }
    return super if params.empty?
    m, r = super(ty - params, pat)
    names = pattern_types(pat)
    return [m + params, r + params] unless names
    [m + names.reject { _1 == "Record" }, r + params.map { |p| [:unknown, "param", p[2], (p[3] | names).freeze].freeze }]
  end

  def pattern_types(pat)
    case pat
    when Sake::AST::PType then [pat.name]
    when Sake::AST::PAlt then (l = pattern_types(pat.left)) && (r = pattern_types(pat.right)) && (l | r)
    when Sake::AST::PValue then pat.value.is_a?(Sake::AST::Lit) && pat.value.value.nil? ? ["Nil"] : nil
    end
  end

  # A case/in without else fails at run time on other values: x is one of the branches' types.
  def case_match(n, env)
    ty = n.subject.is_a?(Sake::AST::LVarGet) ? env.lookup(n.subject.slot) : nil
    r = super
    if !n.else_ && ty
      names = n.clauses.map { |pat, _| pattern_types(pat) }
      ty.each { constrain(_1, names.flatten.uniq) if param?(_1) } if names.all?
    end
    r
  end

  def restrict(env, slot, how)
    ty = env.lookup(slot)
    if ty&.any? { param?(_1) }
      ty = ty.map do |a|
        next a unless param?(a)
        case how
        when :non_nil then [:unknown, "param", a[2], (a[3] | ["Nil"]).freeze].freeze
        when :nil then "Nil"
        when :falsy then "Nil"
        end
      end
      set_narrowed(env, slot, u(*ty.map { [_1] }))
      return
    end
    super
  end

  def requirements
    @program.functions.values.flat_map(&:values).each do |fn|
      next if fn.abstract
      @root = fn.full_name
      call_user(fn, fn.params.each_index.map { |i| [param_atom([fn.full_name, i])] }, nil)
    end
    @req || {}
  end
end

module Observe
  attr_accessor :seen

  def call_user(fn, args, blk, origin)
    args.each_with_index do |v, i|
      name = Sake::Values.type_of(v)
      name = "Record" if name.start_with?("{")
      ((@seen ||= {})[[fn.full_name, i]] ||= Set.new) << name
    end
    super
  end
end

# --- B ---

class NoFixpointTyper < Sake::Typer
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
end

def check_counts(typer)
  c = Hash.new(0)
  typer.checks.each_value { c[_1.verdict] += 1 }
  c
end

def rejected(program, typer, items)
  !Sake::CLI.strict_diagnostics(program, items, typer).empty?
end

ARGV.each do |path|
  src = File.read(path)
  out = { path: }
  program = Sake.load(src, path, out: StringIO.new, input: StringIO.new)
  # A
  local = LocalTyper.new(program).run # fills fields and sites, then each function alone
  reqs = local.requirements
  interp = Sake::Interpreter.new(program)
  interp.extend(Observe)
  saved = $stdout
  $stdout = StringIO.new
  begin
    interp.run
  rescue Sake::RunError
    nil
  ensure
    $stdout = saved
  end
  uni = local.universe
  params = program.functions.values.flat_map(&:values).reject(&:abstract).flat_map { |fn| fn.params.each_index.map { [fn.full_name, _1] } }
  out[:params] = params.map do |key|
    r = reqs[key] || uni
    kind = r.empty? ? "none" : (r.size == 1 ? "one" : (r == uni ? "any" : "union"))
    seen = interp.seen&.[](key)&.to_a || []
    { fn: key[0], i: key[1], kind:, size: r.size, req: kind == "any" ? nil : r.to_a.sort, seen:, bad: seen - r.to_a }
  end
  # B
  full = Sake::Typer.new(program).run
  part = NoFixpointTyper.new(program).run
  # Errors in code the whole-program typer never reaches (functions never called), found locally.
  out[:local_only_errors] = local.checks.reject { |k, _| full.checks.key?(k) }.values.select { _1.verdict == :error }.map { "L#{_1.line} #{_1.op}" }
  out[:checks_full] = check_counts(full)
  out[:checks_local] = check_counts(part)
  out[:reject] = { full: [1, 2].to_h { |l| [l, rejected(program, full, Sake::CLI::STRICT_LEVELS[l])] },
                   local: [1, 2].to_h { |l| [l, rejected(program, part, Sake::CLI::STRICT_LEVELS[l])] } }
  puts JSON.generate(out)
rescue Sake::StaticErrors, StandardError, SystemStackError => e
  puts JSON.generate(path:, error: "#{e.class}: #{e.message[0, 200]}")
end

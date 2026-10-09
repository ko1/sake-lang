# For each function parameter: :check (only scalar built-in checks), :flow (only passed on: returned, stored,
# given to user functions, put in containers; could be a type variable), :look (the body looks at its type:
# narrowing, operators, indexing, fields, dispatch, show). Projects v0's instantiation keys accordingly.
$LOAD_PATH.unshift("/home/ko1/app/sake/lib")
require "sake"
require "sake/typer"
require "stringio"
include Sake::AST
path = ARGV[0]
program = Sake.load(File.read(path), path, out: StringIO.new)
ast = Sake::Lower.program(program)
SCALAR = %w[Integer Float String Symbol Rational Complex Time Regexp Boolean MatchData IO].freeze
SHOWS = %w[Kernel.p Kernel.pp Kernel.puts Kernel.print Kernel.to_s Kernel.inspect Kernel.format Kernel.sprintf Array.join IO.puts IO.print Kernel.dup Hash.dup].freeze
RANK = { check: 0, flow: 1, look: 2 }.freeze

class Scan
  attr_reader :uses, :flows
  def initialize(nparams) = (@n = nparams; @uses = {}; @flows = {}; @alias = {})
  def param_of(slot) = slot < @n ? slot : @alias[slot]
  def note(slot, kind)
    p = param_of(slot) or return
    @uses[p] = RANK[@uses[p] || :check] >= RANK[kind] ? (@uses[p] || :check) : kind
  end
  def go(n, ctx = :flow)
    case n
    when LVarGet then note(n.slot, ctx)
    when LVarSet
      if n.value.is_a?(LVarGet) && param_of(n.value.slot) && n.slot >= @n && !@alias.key?(n.slot) then @alias[n.slot] = param_of(n.value.slot)
      else note(n.slot, :look) if n.slot < @n || @alias.key?(n.slot); go(n.value, :flow) end
    when If then go(n.cond, :look); go(n.then_); go(n.else_)
    when While then go(n.cond, :look); go(n.body)
    when And, Or then go(n.left, :look); go(n.right, ctx)
    when MatchP then go(n.value, :look)
    when CaseIn then go(n.subject, :look); n.clauses.each { go(_1[1]) }; go(n.else_) if n.else_
    when IsNil, UnOp then go(n.value, :look)
    when BinOp then go(n.left, :look); go(n.right, :look)
    when IndexGet then go(n.recv, :look); go(n.key, :look); go(n.extra, :look) if n.extra
    when IndexSet then go(n.recv, :look); go(n.key, :look); go(n.value, :flow)
    when IndexUpdate then go(n.recv, :look); go(n.key, :look); go(n.value, :look)
    when FieldGet then go(n.subject, :look)
    when FieldSet then go(n.subject, :look); go(n.value, :flow)
    when ToS then go(n.value, :look)
    when Splat then go(n.value, :look)
    when MultiWrite then go(n.value, :look); n.targets.each { go(_1, :look) if _1.is_a?(TIndex) }
    when MatchRecord then go(n.value, :look)
    when CallDispatch, CallUnion
      n.args.each_with_index { |a, i| go(a, i.zero? ? :look : :flow) }
      go(n.block) if n.block
    when CallBuiltin
      n.args.each_with_index do |a, i|
        want = n.fn.param_type(i)
        kind = if SHOWS.include?(n.fn.full_name) then :look
               elsif want == "Any" then :flow
               elsif SCALAR.include?(want) then :check
               else :look end # containers, Structs: the result depends on what they hold
        go(a, kind)
      end
      go(n.block) if n.block
    when CallUser
      n.args.each_with_index do |a, i|
        if a.is_a?(LVarGet) && (p = param_of(a.slot)) then (@flows[p] ||= []) << [n.fn, i]; note(a.slot, :check)
        else go(a, :flow) end
      end
      go(n.block) if n.block
    when Return, Next, Break then go(n.value, :flow) if n.value
    else
      return unless n.is_a?(Struct) && n.class.respond_to?(:fields)
      n.class.fields.each do |f|
        v = n[f]
        if v.is_a?(Array) then v.flatten.each { go(_1, :flow) if _1.is_a?(Struct) }
        elsif v.is_a?(Struct) then go(v, :flow) end
      end
    end
  end
end

info = {}.compare_by_identity
ast.functions.each { |fn, f| s = Scan.new(f.nparams); s.go(f.body); info[fn] = [Array.new(f.nparams) { s.uses[_1] || :check }, s.flows] }
# a parameter handed to another function is at least what that function does with it (fixpoint)
loop do
  changed = false
  info.each do |fn, (kinds, flows)|
    flows.each do |i, targets|
      k = targets.map { |g, j| g.equal?(fn) && j == i ? :check : (info[g]&.first&.[](j) || :flow) }.max_by { RANK[_1] }
      k = :flow if RANK[k] < RANK[:flow] && kinds[i] == :check # passed on: a flow at least
      nk = RANK[kinds[i]] >= RANK[k] ? kinds[i] : k
      (kinds[i] = nk; changed = true) if nk != kinds[i]
    end
  end
  break unless changed
end

typer = Sake::Typer.new(program, ast: ast).run
insts = typer.instance_variable_get(:@insts)
fns = program.functions.values.flat_map(&:values)
by_id = fns.to_h { [_1.__id__, _1] }
proj = {}; proj_flow = {}; proj_struct = {}; per_fn = Hash.new(0)
def structural(typer, ty, depth = 0)
  return :deep if depth > 3
  ty.map { |a|
    next a unless a.is_a?(Array)
    case a[0]
    when :array then [:array, structural(typer, typer.sites[a[1]].elem, depth + 1)]
    when :hash then s = typer.hash_sites[a[1]]; [:hash, structural(typer, s.key, depth + 1), structural(typer, s.val, depth + 1)]
    when :set then [:set, structural(typer, typer.set_sites[a[1]].elem, depth + 1)]
    when :tuple then [:tuple, a[1].map { structural(typer, _1, depth + 1) }]
    when :record then [:record, a[1].map { |f, t| [f, structural(typer, t, depth + 1)] }]
    else a end }
end
by_type_id = {}
Sake::Typer::CANON.each_value { by_type_id[_1.__id__] = _1 }

insts.each_key do |key|
  fn = by_id[key[0]]; kinds = info[fn][0]; per_fn[fn] += 1
  proj[[key[0], *key.drop(1).each_with_index.map { |t, i| kinds[i] == :check ? :c : t }]] = true
  proj_flow[[key[0], *key.drop(1).each_with_index.map { |t, i| kinds[i] == :look ? t : kinds[i] }]] = true
  proj_struct[[key[0], *key.drop(1).each_with_index.map { |t, i| kinds[i] == :look ? structural(typer, by_type_id.fetch(t)) : kinds[i] }]] = true
end
all = info.values.sum { _1[0].size }
tally = info.values.flat_map(&:first).tally
puts "#{path.split("/")[-4]}: params #{all} #{tally.sort.to_h}; instantiations #{insts.size} -> check-only projected #{proj.size} -> check+flow projected #{proj_flow.size} -> also containers by element type #{proj_struct.size}"
puts "  top functions by instantiations (name: n, parameter kinds):"
per_fn.sort_by { -_2 }.first(8).each { |fn, n| puts "    #{fn.full_name}: #{n}, #{info[fn][0].join(" ")}" }

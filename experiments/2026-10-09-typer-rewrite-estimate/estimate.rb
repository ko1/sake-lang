# Estimates how many instantiations a signature-based typer would need: a parameter the body only hands to
# built-ins with scalar parameter types (checks) is "check-only"; projecting such parameters out of v0's
# instantiation keys gives the count of bodies to analyze. Also counts run_body calls per pass in v0.
$LOAD_PATH.unshift("/home/ko1/app/sake/lib")
require "sake"
require "sake/typer"
require "stringio"
include Sake::AST
path = ARGV[0]
program = Sake.load(File.read(path), path, out: StringIO.new)
ast = Sake::Lower.program(program)

SCALAR = %w[Integer Float String Symbol Rational Complex Time Regexp Boolean MatchData IO Range].freeze
ECHO = %w[Kernel.p Kernel.pp Kernel.dup Hash.dup Thread.join Kernel.puts Kernel.print Kernel.to_s Kernel.inspect Kernel.format Kernel.sprintf Array.join].freeze

# uses[slot] = :check (only scalar builtin checks), :user (also passed to user functions: transitive), :struct (anything else)
def scan(n, nparams, uses, user_flows, ctx = :struct)
  case n
  when LVarGet
    return unless n.slot < nparams
    rank = { check: 0, user: 1, struct: 2 }
    now = ctx == :check_only_ok ? :check : :struct
    uses[n.slot] = rank[uses[n.slot] || :check] >= rank[now] ? (uses[n.slot] || :check) : now
  when LVarSet
    uses[n.slot] = :struct if n.slot < nparams
    scan(n.value, nparams, uses, user_flows)
  when CallBuiltin
    n.args.each_with_index do |a, i|
      want = n.fn.param_type(i)
      c = a.is_a?(LVarGet) && a.slot < nparams && SCALAR.include?(want) && !ECHO.include?(n.fn.full_name) ? :check_only_ok : :struct
      scan(a, nparams, uses, user_flows, c)
    end
    scan(n.block, nparams, uses, user_flows) if n.block
  when CallUser
    n.args.each_with_index do |a, i|
      if a.is_a?(LVarGet) && a.slot < nparams
        (user_flows[a.slot] ||= []) << [n.fn, i]
        uses[a.slot] = :user if uses[a.slot].nil? || uses[a.slot] == :check
      else
        scan(a, nparams, uses, user_flows)
      end
    end
    scan(n.block, nparams, uses, user_flows) if n.block
  else
    return unless n.is_a?(Struct) && n.class.respond_to?(:fields)
    n.class.fields.each do |f|
      v = n[f]
      if v.is_a?(Array) then v.flatten.each { scan(_1, nparams, uses, user_flows) if _1.is_a?(Struct) }
      elsif v.is_a?(Struct) then scan(v, nparams, uses, user_flows)
      end
    end
  end
end

info = {}.compare_by_identity
ast.functions.each do |fn, f|
  uses = {}
  flows = {}
  scan(f.body, f.nparams, uses, flows)
  info[fn] = [Array.new(f.nparams) { uses[_1] || :check }, flows] # unused parameter: check-only (nothing observes it)
end
# transitive: a :user parameter is check-only if every function it flows to treats that position as check-only
changed = true
while changed
  changed = false
  info.each do |fn, (kinds, flows)|
    kinds.each_index do |i|
      next unless kinds[i] == :user
      k = flows[i].all? { |g, j| (gk = info[g]&.first&.[](j)) == :check || (g.equal?(fn) && j == i) } ? :check : :struct
      next if k == :user
      kinds[i] = k if k == :struct || flows[i].all? { |g, j| g.equal?(fn) || info[g]&.first&.[](j) == :check }
      changed = true if kinds[i] != :user
    end
  end
end
info.each { |_, (kinds, _)| kinds.map! { _1 == :user ? :check : _1 } } # only self-recursive flows left

# v0: run_body calls per pass
CALLS = Hash.new(0)
Sake::Typer.prepend(Module.new do
  def run_body(fn, args, blk)
    CALLS[@passes] += 1
    super
  end
end)
typer = Sake::Typer.new(program, ast: ast).run
insts = typer.instance_variable_get(:@insts)
projected = {}
insts.each_key do |key|
  fn = program.functions.values.flat_map(&:values).find { _1.__id__ == key[0] } # key = [fn id, *type ids]
  kinds = info[fn]&.first || []
  projected[[key[0], *key.drop(1).each_with_index.map { |t, i| kinds[i] == :check ? :c : t }]] = true
end
params = info.values.sum { _1[0].size }
checks = info.values.sum { _1[0].count(:check) }
puts "#{path.split("/")[-4]}: params #{params}, check-only #{checks} (#{(100.0 * checks / params).round}%), " \
     "instantiations #{insts.size} -> projected #{projected.size}; run_body per pass: #{CALLS.sort.map { _2 }.join(" ")}"

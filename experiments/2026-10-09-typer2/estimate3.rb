# Per parameter: escapes? (returned, stored, passed on, put in a container), written? (a container write through
# it, directly or in a callee). A parameter that neither escapes nor is written can be keyed by the shape of its
# type (containers by element type) instead of by site identity. Projects v0's instantiation keys that way.
$LOAD_PATH.unshift("/home/ko1/app/sake/lib")
require "sake"
require "sake/typer"
require "stringio"
include Sake::AST
path = ARGV[0]
program = Sake.load(File.read(path), path, out: StringIO.new)
ast = Sake::Lower.program(program)
WRITERS = %w[Array.push Array.append Array.unshift Array.concat Array.insert Array.delete Array.delete_at Array.delete_if Array.pop Array.shift Array.clear
             Array.sort! Array.map! Array.select! Array.reject! Array.uniq! Array.compact! Array.flatten! Array.reverse! Array.shuffle! Array.fill Array.replace Array.keep_if
             Hash.store Hash.delete Hash.clear Hash.merge! Hash.update Hash.transform_values! Hash.transform_keys! Hash.select! Hash.reject! Hash.delete_if Hash.keep_if Hash.compact!
             Set.add Set.add? Set.delete Set.merge Set.clear Set.subtract Queue.push Queue.pop Queue.close Mutex.synchronize Thread.join IO.puts IO.print IO.write IO.close IO.read IO.gets].freeze
Info = Struct.new(:escapes, :written, :flows)
class Scan
  attr_reader :info
  def initialize(nparams) = (@n = nparams; @info = Array.new(nparams) { Info.new(false, false, []) }; @alias = {})
  def param_of(slot) = slot < @n ? slot : @alias[slot]
  def mark(n, what) = n.is_a?(LVarGet) && (p = param_of(n.slot)) && @info[p][what] = true
  def go(n, ctx = :escape)
    case n
    when LVarGet then mark(n, :escapes) if ctx == :escape
    when LVarSet
      if n.value.is_a?(LVarGet) && param_of(n.value.slot) && n.slot >= @n && !@alias.key?(n.slot) then @alias[n.slot] = param_of(n.value.slot)
      else (p = param_of(n.slot)) && (@info[p].escapes = true); go(n.value, :escape) end
    when If then go(n.cond, :read); go(n.then_); go(n.else_)
    when While then go(n.cond, :read); go(n.body)
    when And, Or then go(n.left, :read); go(n.right, ctx)
    when MatchP, IsNil, UnOp, ToS, MatchRecord then go(n.value, :read)
    when CaseIn then go(n.subject, :read); n.clauses.each { go(_1[1]) }; go(n.else_) if n.else_
    when BinOp then go(n.left, :read); go(n.right, :read)
    when IndexGet then go(n.recv, :read); go(n.key, :read); go(n.extra, :read) if n.extra
    when IndexSet then mark(n.recv, :written); go(n.recv, :read); go(n.key, :read); go(n.value, :escape)
    when IndexUpdate then mark(n.recv, :written); go(n.recv, :read); go(n.key, :read); go(n.value, :read)
    when FieldGet then go(n.subject, :read)
    when FieldSet then mark(n.subject, :written); go(n.subject, :read); go(n.value, :escape)
    when Splat then go(n.value, :read)
    when MultiWrite then go(n.value, :read); n.targets.each { |t| t.is_a?(TIndex) && (mark(t.recv, :written); go(t.recv, :read); go(t.key, :read)) }
    when CallDispatch, CallUnion
      n.args.each_with_index { |a, i| go(a, i.zero? ? :read : :escape) } # dispatch targets are user functions: conservative
      n.args.each { |a| mark(a, :escapes) }
      go(n.block) if n.block
    when CallBuiltin
      n.args.each_with_index do |a, i|
        want = n.fn.param_type(i)
        mark(a, :written) if i.zero? && WRITERS.include?(n.fn.full_name)
        go(a, want == "Any" ? :escape : :read) # "Any": stored or shown (puts): escapes
      end
      go(n.block) if n.block
    when CallUser
      n.args.each_with_index do |a, i|
        if a.is_a?(LVarGet) && (p = param_of(a.slot)) then @info[p].flows << [n.fn, i]
        else go(a, :escape) end
      end
      go(n.block) if n.block
    when Return, Next, Break then go(n.value, :escape) if n.value
    when Yield then n.args.each { go(_1, :escape) }
    else
      return unless n.is_a?(Struct) && n.class.respond_to?(:fields)
      n.class.fields.each do |f|
        v = n[f]
        if v.is_a?(Array) then v.flatten.each { go(_1, :escape) if _1.is_a?(Struct) }
        elsif v.is_a?(Struct) then go(v, :escape) end
      end
    end
  end
end
info = {}.compare_by_identity
ast.functions.each { |fn, f| s = Scan.new(f.nparams); s.go(f.body); info[fn] = s.info }
loop do
  changed = false
  info.each do |fn, ps|
    ps.each do |p|
      p.flows.each do |g, j|
        q = info[g]&.[](j) or (p.escapes = true; next)
        (p.escapes = true; changed = true) if q.escapes && !p.escapes
        (p.written = true; changed = true) if q.written && !p.written
      end
    end
  end
  break unless changed
end

def structural(typer, ty, depth = 0)
  return :deep if depth > 3
  ty.map do |a|
    next a unless a.is_a?(Array)
    case a[0]
    when :array then [:array, structural(typer, typer.sites[a[1]].elem, depth + 1)]
    when :hash then s = typer.hash_sites[a[1]]; [:hash, structural(typer, s.key, depth + 1), structural(typer, s.val, depth + 1)]
    when :set then [:set, structural(typer, typer.set_sites[a[1]].elem, depth + 1)]
    when :tuple then [:tuple, a[1].map { structural(typer, _1, depth + 1) }]
    when :record then [:record, a[1].map { |f, t| [f, structural(typer, t, depth + 1)] }]
    else a
    end
  end
end
typer = Sake::Typer.new(program, ast: ast).run
insts = typer.instance_variable_get(:@insts)
by_id = program.functions.values.flat_map(&:values).to_h { [_1.__id__, _1] }
by_type = {}
Sake::Typer::CANON.each_value { by_type[_1.__id__] = _1 }
proj = {}
per_fn = Hash.new(0); per_fn_proj = Hash.new { |h, k| h[k] = {} }
insts.each_key do |key|
  fn = by_id[key[0]]
  k = [key[0], *key.drop(1).each_with_index.map { |t, i| (p = info[fn][i]) && !p.escapes && !p.written ? structural(typer, by_type.fetch(t)) : t }]
  proj[k] = true; per_fn[fn] += 1; per_fn_proj[fn][k] = true
end
ps = info.values.flatten
puts "#{path.split("/")[-4]}: params #{ps.size}: escape #{ps.count(&:escapes)}, written #{ps.count(&:written)}, read-only & kept #{ps.count { !_1.escapes && !_1.written }}; " \
     "instantiations #{insts.size} -> shape-keyed read-only params #{proj.size}"
per_fn.sort_by { -_2 }.first(6).each { |fn, n| puts "    #{fn.full_name}: #{n} -> #{per_fn_proj[fn].size}  (#{info[fn].map { _1.escapes ? "esc" : (_1.written ? "wr" : "ro") }.join(" ")})" }

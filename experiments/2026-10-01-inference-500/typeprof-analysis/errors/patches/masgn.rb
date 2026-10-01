# Counterfactual M: `a, b = expr` where expr is an Array[T] instance (not a tuple) assigns T to each
# target. TypeProf 0.31.1 (MAsgnBox#run0, "TODO: call to_ary?") assigns the whole array to `a` and
# nothing to `b`.
require "typeprof"
TypeProf::Core::MAsgnBox.prepend(Module.new do
  def run0(genv, changes)
    edges = []
    @value.each_type do |ty|
      if ty.is_a?(TypeProf::Core::Type::Array)
        edges.concat(ty.splat_assign(genv, @lefts, @rest_elem, @rights))
      elsif ty.is_a?(TypeProf::Core::Type::Instance) && ty.mod == genv.mod_ary && ty.args[0]
        elem = ty.args[0]
        (@lefts + (@rights || [])).each { edges << [elem, _1] }
        edges << [elem, @rest_elem] if @rest_elem
      elsif @lefts.size >= 1
        edges << [TypeProf::Core::Source.new(ty), @lefts[0]]
      elsif @rights && @rights.size >= 1
        edges << [TypeProf::Core::Source.new(ty), @rights[0]]
      else
        edges << [TypeProf::Core::Source.new(ty), @rest_elem]
      end
    end
    edges.each { |src, dst| changes.add_edge(genv, src, dst) }
  end
end)

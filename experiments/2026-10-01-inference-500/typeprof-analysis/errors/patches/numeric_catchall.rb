# Counterfactual N: when an earlier overload already matched, skip a later catch-all overload whose
# single parameter is Numeric (Integer#% (Numeric) -> Numeric, Float#% ..., etc.).
# TypeProf 0.31.1 unions the return types of *all* matching overloads, so 7 % 2 : Integer | Numeric.
require "typeprof"
TypeProf::Core::MethodDeclBox.prepend(Module.new do
  def resolve_overloads(changes, genv, node, param_map, a_args, ret, &blk)
    return super if @method_types.size == 1
    matched = false
    @method_types.each do |mt|
      next if matched && numeric_catchall?(mt)
      matched = true if resolve_overload(changes, genv, mt, node, param_map, a_args, ret, false, &blk)
    end
    unless matched
      meth = node.mid_code_range ? :mid_code_range : :code_range
      changes.add_diagnostic(meth, "failed to resolve overloads")
    end
  end

  def numeric_catchall?(mt)
    ps = mt.req_positionals
    ps.size == 1 && mt.opt_positionals.empty? && !mt.rest_positionals &&
      ps[0].is_a?(TypeProf::Core::AST::SigTyInstanceNode) && ps[0].cpath == [:Numeric]
  end
end)

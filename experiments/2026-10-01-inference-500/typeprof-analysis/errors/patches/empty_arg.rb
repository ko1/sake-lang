# Counterfactual E: an argument whose vertex has no type at all (nothing ever flows into it, e.g. a
# parameter of a method TypeProf never saw called, or the result of a call that already failed) is
# accepted by every RBS parameter type. TypeProf 0.31.1 (AST.typecheck_for_module) rejects it, so
# such a value fails every overload ("failed to resolve overloads" / "wrong type of arguments").
require "typeprof"
TypeProf::Core::AST.singleton_class.prepend(Module.new do
  def typecheck_for_module(genv, changes, f_mod, f_args, a_vtx, subst)
    changes.add_edge(genv, a_vtx, changes.target)
    return true if a_vtx.types.empty?
    super
  end
end)
TypeProf::Core::AST::SigTyInterfaceNode.prepend(Module.new do
  def typecheck(genv, changes, vtx, subst)
    changes.add_edge(genv, vtx, changes.target)
    return true if vtx.types.empty?
    super
  end
end)

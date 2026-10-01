# Counterfactual I: treat every RBS interface type (_ToS, _ToF, _Inspect, _ToStr, ...) as satisfied.
# TypeProf 0.31.1 checks interfaces nominally (SigTyInterfaceNode#typecheck -> typecheck_for_module),
# so only String/Array/Hash (which a shim declares to include a few interfaces) ever pass.
require "typeprof"
TypeProf::Core::AST::SigTyInterfaceNode.prepend(Module.new do
  def typecheck(genv, changes, vtx, subst) = true
end)

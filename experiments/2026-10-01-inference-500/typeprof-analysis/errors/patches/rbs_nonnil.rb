# Counterfactual L: library (RBS) return values are never nil: drop nil from `T?` and from `T | nil`
# when TypeProf builds a covariant (returned / yielded) vertex from an RBS type.
require "typeprof"
TypeProf::Core::AST::SigTyOptionalNode.prepend(Module.new do
  def covariant_vertex0(genv, changes, vtx, subst) = @type.covariant_vertex0(genv, changes, vtx, subst)
end)
TypeProf::Core::AST::SigTyUnionNode.prepend(Module.new do
  def covariant_vertex0(genv, changes, vtx, subst)
    @types.each do |t|
      next if t.is_a?(TypeProf::Core::AST::SigTyBaseNilNode)
      t.covariant_vertex0(genv, changes, vtx, subst)
    end
  end
end)

# Counterfactual U: the literal `nil` in the program has no type (an empty vertex) instead of nil.
require "typeprof"
TypeProf::Core::AST::NilNode.prepend(Module.new do
  def install0(genv) = TypeProf::Core::Source.new
end)

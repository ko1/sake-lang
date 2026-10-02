# Counterfactual S: when TypeProf instantiates an included module's type arguments for a concrete
# receiver type (GlobalEnv#get_instance_type, e.g. Array[X] -> Enumerable[X]), memoize the RBS-node
# vertices per receiver type arguments instead of per RBS node. TypeProf 0.31.1
# (ChangeSet#new_covariant_vertex) keys them by the node alone, so within one call site the `Elem` of
# Array's `include Enumerable[Elem]` is one vertex shared by the receiver (Array[Pt], when sort_by /
# min_by / max_by is found in Enumerable) and by the block's value (an Array key like [pt.x, pt.y],
# when it is checked against Comparable | Array[untyped]): the key's element types leak into the
# block parameter.
require "typeprof"
require "delegate"

class KeyedChanges < SimpleDelegator
  def initialize(changes, extra)
    super(changes)
    @extra = extra
  end

  def new_covariant_vertex(genv, node) = (__getobj__.covariant_types[[node, @extra]] ||= TypeProf::Core::Vertex.new(node))
end

TypeProf::Core::GlobalEnv.prepend(Module.new do
  def get_instance_type(mod, type_args, changes, base_ty_env, base_ty)
    return super unless changes && base_ty.respond_to?(:args)
    super(mod, type_args, KeyedChanges.new(changes, base_ty.args.map(&:object_id)), base_ty_env, base_ty)
  end
end)

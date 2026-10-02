# Counterfactual I: check RBS interface types (_ToS, _ToF, _Inspect, _ToStr, ...) structurally: an
# actual type satisfies the interface if its class (or an ancestor) has every method the interface
# declares. TypeProf 0.31.1 checks interfaces nominally (SigTyInterfaceNode#typecheck ->
# typecheck_for_module), so only String/Array/Hash, which a built-in shim declares to include a few
# interfaces, ever pass. Like TypeProf's own check, one matching type in a union is enough.
require "typeprof"
TypeProf::Core::AST::SigTyInterfaceNode.prepend(Module.new do
  def typecheck(genv, changes, vtx, subst)
    changes.add_depended_static_read(@static_ret.last)
    cpath = @static_ret.last.cpath
    return false unless cpath
    changes.add_edge(genv, vtx, changes.target)
    iface = genv.resolve_cpath(cpath)
    mids = iface.methods[false].select { |_, me| me.exist? }.keys
    vtx.each_type do |ty|
      base = ty.base_type(genv)
      next unless base.respond_to?(:mod)
      singleton = base.is_a?(TypeProf::Core::Type::Singleton)
      ok = mids.all? do |mid|
        genv.each_superclass(base.mod, singleton) do |m, s|
          changes.add_depended_superclass(m)
          break true if m.get_method(s, mid).exist?
        end == true
      end
      return true if ok
    end
    false
  end
end)

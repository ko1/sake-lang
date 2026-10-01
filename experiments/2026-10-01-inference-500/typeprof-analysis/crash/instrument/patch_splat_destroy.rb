# Experiment only (loaded with -r; the installed gem is untouched): make a destroyed SplatBox
# unsubscribe from its array vertex, to separate the leak from the re-run cycle.
require "typeprof"
TypeProf::Core::SplatBox.prepend(Module.new { def destroy(genv) = (super; @ary.remove_edge(genv, self)) })

# Diagnostic monkeypatch (not a proposed fix): reuse the SplatBox from the previous run of the
# same parent box instead of destroying it and creating a new one with a fresh `ret` vertex.
# usage: ruby -I tools -rreuse_splat $(gem contents typeprof | grep bin/typeprof) FILE.rb
require "typeprof"
class TypeProf::Core::ChangeSet
  def add_splat_box(genv, arg, idx = nil)
    key = [:splat, arg, idx]
    @new_boxes[key] ||= (@boxes.delete(key) || TypeProf::Core::SplatBox.new(@node, genv, arg, idx))
  end
end

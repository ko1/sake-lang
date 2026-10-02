# Diagnostic monkeypatch (not a proposed fix): print "untyped" for any vertex nested deeper than
# CAP_SHOW_DEPTH (default 4) inside one signature, so Vertex#show cannot unfold a cyclic type graph exponentially.
require "typeprof"
module CapShow
  def show
    d = (Fiber[:cap_show_depth] ||= 0)
    return "untyped" if d >= Integer(ENV.fetch("CAP_SHOW_DEPTH", "4"))
    Fiber[:cap_show_depth] = d + 1
    super
  ensure
    Fiber[:cap_show_depth] = d
  end
end
TypeProf::Core::BasicVertex.prepend(CapShow)

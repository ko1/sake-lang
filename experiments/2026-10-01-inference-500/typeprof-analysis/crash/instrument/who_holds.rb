# Diagnostic only: after 2 s, find which objects reference an old destroyed SplatBox (one hop, then two).
require "typeprof"
require "objspace"
Thread.new do
  sleep 2
  GC.start
  sp = ObjectSpace.each_object(TypeProf::Core::SplatBox).find { _1.instance_variable_get(:@destroyed) }
  holders = ->(target) { r = []; ObjectSpace.each_object { |o| r << o if !o.equal?(target) && (ObjectSpace.reachable_objects_from(o) || []).any? { _1.equal?(target) } rescue nil }; r }
  h1 = holders.(sp)
  h1.first(5).each do |h|
    h2 = holders.(h).reject { _1.is_a?(Array) && _1.size > 1000 }
    $stderr.puts "HOLD #{h.class} (size=#{h.respond_to?(:size) ? h.size : '-'}) <- #{h2.first(4).map { |x| x.class.name + (x.is_a?(TypeProf::Core::MethodCallBox) ? "(#{x.instance_variable_get(:@mid)})" : '') }.join(', ')}"
  end
  exit! 0
end

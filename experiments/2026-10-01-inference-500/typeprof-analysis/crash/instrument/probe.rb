# Observation-only probe (no behavior change): every PROBE_SECS print cumulative counts of
# SplatBox creations, Box#run calls per box class, the most re-run box, live/destroyed SplatBox objects,
# and the number of outgoing edges of one SplatBox's array vertex.
require "typeprof"
$probe_new = Hash.new(0); $probe_runs = Hash.new(0); $probe_box_runs = Hash.new(0)
TypeProf::Core::SplatBox.prepend(Module.new { def initialize(*) = ($probe_new[:splat] += 1; super) })
TypeProf::Core::Vertex.prepend(Module.new { def initialize(*) = ($probe_new[:vertex] += 1; super) })
TypeProf::Core::Box.prepend(Module.new { def run(genv) = ($probe_runs[self.class.name.split("::").last] += 1; $probe_box_runs[self] += 1; super) })
secs = Float(ENV.fetch("PROBE_SECS", "2")); n = Integer(ENV.fetch("PROBE_N", "3"))
Thread.new do
  n.times do |k|
    sleep secs
    GC.start
    live = ObjectSpace.each_object(TypeProf::Core::SplatBox).count
    sp = ObjectSpace.each_object(TypeProf::Core::SplatBox).first
    fanout = sp ? sp.ary.instance_variable_get(:@next_vtxs).size : 0
    destroyed = ObjectSpace.each_object(TypeProf::Core::SplatBox).count { _1.instance_variable_get(:@destroyed) }
    b, r = $probe_box_runs.max_by { _2 }
    desc = b.is_a?(TypeProf::Core::MethodCallBox) ? "MethodCallBox(#{b.instance_variable_get(:@mid)})" : b.class.name
    $stderr.puts "PROBE t=#{(k + 1) * secs}s new=#{$probe_new} runs=#{$probe_runs} live_splat=#{live} destroyed=#{destroyed} ary_fanout=#{fanout} top=#{desc}x#{r} rss=#{File.read("/proc/self/status")[/VmRSS:\s+(\d+)/, 1].to_i / 1024}MB"
  end
  exit! 0
end

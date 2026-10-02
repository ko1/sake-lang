# Diagnostic (observation only): every LT_STEP seconds (default 10) up to LT_END (default 120), print how many
# SplatBoxes were created so far, how many edges the last splatted vertex has (dead boxes are never unlinked), and RSS.
require "typeprof"
$arg = nil; $n = 0
TypeProf::Core::SplatBox.prepend(Module.new { def initialize(node, genv, arg, idx) = ($arg = arg; $n += 1; super) })
Thread.new { step = Float(ENV.fetch("LT_STEP", "10")); (Float(ENV.fetch("LT_END", "120")) / step).to_i.times { sleep step; $stderr.puts "t=#{((_1+1)*step).to_i}s splatboxes created=#{$n} next_vtxs of arg=#{$arg.instance_variable_get(:@next_vtxs).size rescue '?'} live boxes=#{$box_counts[TypeProf::Core::Box]} rss=#{File.read("/proc/self/status")[/VmRSS:\s*(\d+)/,1].to_i/1024}MB" }; exit! 0 }
load Gem.bin_path("typeprof", "typeprof")

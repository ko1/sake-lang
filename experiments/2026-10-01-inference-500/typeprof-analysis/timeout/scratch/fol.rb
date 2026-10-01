require "typeprof"
$arg = nil; $n = 0
TypeProf::Core::SplatBox.prepend(Module.new { def initialize(node, genv, arg, idx) = ($arg = arg; $n += 1; super) })
Thread.new { 4.times { sleep 2; $stderr.puts "t=#{(_1+1)*2}s splatboxes created=#{$n} next_vtxs of arg=#{$arg.instance_variable_get(:@next_vtxs).size rescue '?'} live boxes=#{$box_counts[TypeProf::Core::Box]} rss=#{File.read("/proc/self/status")[/VmRSS:\s*(\d+)/,1].to_i/1024}MB" }; exit! 0 }
load Gem.bin_path("typeprof", "typeprof")

require "typeprof"
$log = []
TypeProf::Core::SplatBox.prepend(Module.new { def initialize(node, genv, arg, idx) = ($log << [arg.object_id, idx, caller(1, 12).grep(/typeprof/).map { _1[/core\/(.*?:\d+)/, 1] }.join(" < ")]; super) })
TypeProf::Core::Box.prepend(Module.new { def destroy(genv) = ($log << [:destroy, to_s] if is_a?(TypeProf::Core::SplatBox); super) })
Thread.new { sleep 2; $log.first(14).each { $stderr.puts _1.inspect }; $stderr.puts $log.map { _1[0] }.uniq.size; exit! 0 }
load Gem.bin_path("typeprof", "typeprof")

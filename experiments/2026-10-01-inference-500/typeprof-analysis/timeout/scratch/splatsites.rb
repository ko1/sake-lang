require "typeprof"
$s = Hash.new(0)
TypeProf::Core::SplatBox.prepend(Module.new { def initialize(node, genv, arg, idx) = ($s[[node.code_range.first.lineno, idx, arg.show]] += 1 rescue nil; super) })
at_exit { $s.each { $stderr.puts "SPLAT line=#{_1[0]} idx=#{_1[1]} n=#{_2} arg=#{_1[2][0, 80]}" } }
load Gem.bin_path("typeprof", "typeprof")

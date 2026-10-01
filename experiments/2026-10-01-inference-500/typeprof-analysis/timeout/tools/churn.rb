# Diagnostic (observation only, no behavior change): after CHURN_SECS (default 10) of analysis, report
# how often SplatBoxes were re-created for the same (vertex, index) key, and the most re-run MethodCallBox.
require "typeprof"
$splat = Hash.new(0); $runs = Hash.new(0)
TypeProf::Core::SplatBox.prepend(Module.new { def initialize(node, genv, arg, idx) = ($splat[[arg, idx]] += 1; super) })
TypeProf::Core::Box.prepend(Module.new { def run(genv) = ($runs[self] += 1; super) })
Thread.new do
  sleep Float(ENV.fetch("CHURN_SECS", "10"))
  b, n = $runs.max_by { _2 }
  mx = $splat.values.max || 0
  $stderr.puts "CHURN max_splat_recreations=#{mx} top_box=#{b} runs=#{n} mid=#{b.instance_variable_get(:@mid)} at=#{b.node.code_range rescue nil}"
  exit! 3
end

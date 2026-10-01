# usage: ruby tools/boxcount.rb SECONDS FILE.rb -- run TypeProf in-process; after SECONDS print the boxes that ran most
secs = Float(ARGV.shift)
require "typeprof"
$runs = Hash.new(0)
TypeProf::Core::Box.prepend(Module.new { def run(genv) = ($runs[self] += 1; super) })
Thread.new do
  sleep secs
  $stderr.puts "total box runs: #{$runs.values.sum}, distinct boxes: #{$runs.size}"
  $runs.sort_by { -_2 }.first(12).each do |b, n|
    $stderr.puts "#{n}\t#{b}\t#{b.node.class.name.split("::").last} #{b.node.code_range rescue nil}\t#{(b.instance_variable_get(:@mid) rescue nil)}"
  end
  exit! 0
end
load Gem.bin_path("typeprof", "typeprof")

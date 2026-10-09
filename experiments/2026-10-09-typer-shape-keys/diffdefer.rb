$LOAD_PATH.unshift("/home/ko1/app/sake/lib")
require "sake"; require "sake/typer"; require "stringio"
path = ARGV[0]
program = Sake.load(File.read(path), path, out: StringIO.new)
ids = ->(t) { t.checks.values.map { |c| [c.file&.split("/")&.last, c.line, c.column, c.op, c.arg, c.verdict] } }
res = [false, true].map do |on|
  Sake::Typer::DEFER_BOTTOM[0] = on
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  t = Sake::Typer.new(program).run
  [t, ids.(t), Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0]
end
(a, ia, ta), (b, ib, tb) = res
puts "#{path.split("/")[-4]}: defer off/on: checks #{ia.size}/#{ib.size} (only off #{(ia - ib).size}, only on #{(ib - ia).size}); dead #{a.dead_functions.size}/#{b.dead_functions.size}; insts #{a.instance_variable_get(:@insts).size}/#{b.instance_variable_get(:@insts).size}; passes #{a.passes}/#{b.passes}; time #{ta.round(2)}/#{tb.round(2)} s"
(ia - ib).first(3).each { puts "  - #{_1.inspect}" }
puts "  dead only with defer: #{(b.dead_functions - a.dead_functions).map(&:full_name).first(6).inspect}"

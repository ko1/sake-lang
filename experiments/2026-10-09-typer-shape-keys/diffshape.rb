# Compares Typer's checks with shape keys off and on, and counts instantiations and time.
$LOAD_PATH.unshift("/home/ko1/app/sake/lib")
require "sake"; require "sake/typer"; require "stringio"
path = ARGV[0]
program = Sake.load(File.read(path), path, out: StringIO.new)
ids = ->(t) { t.checks.values.map { |c| [c.file&.split("/")&.last, c.line, c.column, c.op, c.arg, c.verdict] } }
res = [false, true].map do |on|
  Sake::Typer::SHAPE_KEYS[0] = on
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  t = Sake::Typer.new(program).run
  [t, ids.(t), Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0]
end
(a, ia, ta), (b, ib, tb) = res
puts "#{path.split("/")[-4]}: checks off #{ia.size} on #{ib.size}; only off #{(ia - ib).size}, only on #{(ib - ia).size}; dead off #{a.dead_functions.size} on #{b.dead_functions.size}"
(ia - ib).first(5).each { puts "  - #{_1.inspect}" }; (ib - ia).first(5).each { puts "  + #{_1.inspect}" }
puts "  instantiations off #{a.instance_variable_get(:@insts).size} on #{b.instance_variable_get(:@insts).size}; passes #{a.passes} / #{b.passes}; typer time #{ta.round(2)} / #{tb.round(2)} s"
ok = b.instance_variable_get(:@shape_ok)
puts "  shape-keyable parameters: #{ok.values.flatten.count(true)} of #{ok.values.flatten.size}"

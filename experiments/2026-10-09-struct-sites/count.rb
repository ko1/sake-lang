$LOAD_PATH.unshift("/home/ko1/app/sake/lib"); require "sake"; require "sake/typer"; require "stringio"
program = Sake.load(File.read(ARGV[0]), ARGV[0], out: StringIO.new)
t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
t = Sake::Typer.new(program).run
t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
ik = t.instance_variable_get(:@inst_keys)
puts "time #{(t1 - t0).round(2)}s instantiations #{ik&.size} sites #{t.instance_variable_get(:@sites).size} objs #{t.instance_variable_get(:@obj_sites)&.size.inspect} passes #{t.passes}"

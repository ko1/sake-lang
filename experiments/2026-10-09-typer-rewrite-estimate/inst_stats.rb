# Counts, for one program: user functions, instantiations (function x argument types), passes and time per pass.
$LOAD_PATH.unshift(File.expand_path("lib", "/home/ko1/app/sake"))
require "sake"
require "sake/typer"
require "stringio"
path = ARGV[0]
program = Sake.load(File.read(path), path, out: StringIO.new)
t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
typer = Sake::Typer.new(program)
# time each pass by wrapping ev of the main body: easier to measure whole run and read passes
typer.run
t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
fns = program.functions.values.flat_map(&:values)
insts = typer.instance_variable_get(:@insts)
by_fn = Hash.new(0)
insts.each_key { |k| by_fn[k[0]] += 1 }
yielders = fns.count(&:yields)
puts "#{File.basename(File.dirname(File.dirname(File.dirname(path))))}: functions #{fns.size} (yielding #{yielders}), instantiations #{insts.size}, " \
     "functions with >1 instantiation #{by_fn.count { _2 > 1 }}, max per function #{by_fn.values.max}, passes #{typer.passes}, typer time #{(t1 - t0).round(2)} s"
dist = by_fn.values.tally.sort.first(8).map { |n, c| "#{n}:#{c}" }.join(" ")
puts "  instantiations per function (n:functions) #{dist}"

# Typer CPU time over programs: ruby -I<sake>/lib typer_time.rb FILE.sake...
# Prints the total and the instantiation / site counts (summed over programs).
require "sake"
require "sake/typer"
require "stringio"
cpu = 0.0
insts = 0
sites = 0
ARGV.each do |path|
  program = Sake.load(File.read(path), path, out: StringIO.new)
  t0 = Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID)
  typer = Sake::Typer.new(program).run
  cpu += Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID) - t0
  insts += typer.instance_variable_get(:@returns).size
  sites += typer.sites.size + typer.hash_sites.size + typer.set_sites.size
rescue Sake::StaticErrors
  nil
end
puts format("typer cpu %.2f s, instantiations %d, sites %d, programs %d", cpu, insts, sites, ARGV.size)

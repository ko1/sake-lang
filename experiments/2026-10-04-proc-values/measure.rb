# usage: ruby -I<sake>/lib measure.rb FILE.sake...
# Per program: typer CPU time (median of 5, ms), passes, instantiations (functions and Procs analyzed
# per argument types), checks by verdict, and the strict findings at levels 1 and 2.
require "sake"
require "sake/cli"
require "sake/typer"
require "stringio"

def cpu = Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID)

puts "| program | typer ms (min..max of 5) | passes | fn inst | proc inst | proven | partial | error | unknown | L1 findings | L2 findings |"
puts "|---|---|---|---|---|---|---|---|---|---|---|"
ARGV.each do |path|
  program = Sake.load(File.read(path), path, out: StringIO.new)
  times = []
  typer = nil
  5.times do
    t0 = cpu
    typer = Sake::Typer.new(program).run
    times << ((cpu - t0) * 1000)
  end
  returns = typer.instance_variable_get(:@returns)
  procs = returns.keys.count { _1[0] == :proc }
  verdicts = typer.checks.values.map(&:verdict).tally
  levels = Sake::CLI::STRICT_LEVELS
  l1 = Sake::CLI.strict_diagnostics(program, levels[1], typer).size
  l2 = Sake::CLI.strict_diagnostics(program, levels[2], typer).size
  ts = times.sort
  puts "| #{File.basename(path)} | #{format("%.1f", ts[2])} (#{format("%.1f", ts[0])}..#{format("%.1f", ts[-1])}) | #{typer.passes} | " \
       "#{returns.size - procs} | #{procs} | #{verdicts[:proven] || 0} | #{verdicts[:partial] || 0} | #{verdicts[:error] || 0} | " \
       "#{verdicts[:unknown] || 0} | #{l1} | #{l2} |"
end

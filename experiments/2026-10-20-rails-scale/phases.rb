# Runs `sake ARGS` (normally -c FILE) and prints the wall time of each phase to stderr:
# the generators (stage 0), parsing and resolving, the resolver's check_all, lowering, and the type checker.
$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sake/cli"
require "sake/typer"
T = Hash.new(0.0)
def timed(mod, meth, label, singleton: false)
  m = Module.new do
    define_method(meth) do |*a, **k, &b|
      t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin
        super(*a, **k, &b)
      ensure
        T[label] += Process.clock_gettime(Process::CLOCK_MONOTONIC) - t
      end
    end
  end
  singleton ? mod.singleton_class.prepend(m) : mod.prepend(m)
end
timed(Sake, :generate_stage0, "generate", singleton: true)
timed(Sake::Resolver, :resolve, "resolve (all)")
timed(Sake::Resolver, :check_all, "resolve: check_all")
timed(Sake::Typer, :run, "typer")
timed(Sake::Lower, :program, "lower")
t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
st = Sake::CLI.main(ARGV)
T["total"] = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
T.each { |k, v| $stderr.printf("%-20s %8.2fs\n", k, v) }
exit st

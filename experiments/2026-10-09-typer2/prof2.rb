$LOAD_PATH.unshift("/home/ko1/app/sake/lib")
require "sake"; require "sake/typer2"; require "stringio"; require "stackprof"
path = ARGV[0]
program = Sake.load(File.read(path), path, out: StringIO.new)
klass = ENV["T"] == "1" ? Sake::Typer : Sake::Typer2
prof = StackProf.run(mode: :cpu, interval: 1000) { klass.new(program).run }
StackProf::Report.new(prof).print_text(false, 28)

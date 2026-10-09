$LOAD_PATH.unshift("/home/ko1/app/sake/lib")
require "sake"; require "sake/typer2"; require "stringio"
path = ARGV[0]
program = Sake.load(File.read(path), path, out: StringIO.new)
ids = ->(typer) { typer.checks.values.map { |c| [c.file, c.line, c.column, c.op, c.arg, c.verdict] } }
t1 = Sake::Typer.new(program).run
t2 = Sake::Typer2.new(program).run
a = ids.(t1); b = ids.(t2)
puts "v0 #{a.size} checks, typer2 #{b.size}; only v0 #{(a - b).size}, only typer2 #{(b - a).size}"
(a - b).group_by { _1[0] }.each { |f, cs| puts "  #{f || "main"}: lines #{cs.map { _1[1] }.uniq.sort.inspect}" }
(b - a).first(5).each { puts "  + #{_1.inspect}" }
dead1 = t1.dead_functions.map(&:full_name); dead2 = t2.dead_functions.map(&:full_name)
puts "dead functions: v0 #{dead1.size}, typer2 #{dead2.size}; only typer2 dead: #{(dead2 - dead1).first(10).inspect}"

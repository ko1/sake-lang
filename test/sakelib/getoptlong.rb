require "getoptlong"

# Ruby's GetoptLong reads the global ARGV; the Sake port takes the Array. Ruby's error classes and
# constants are Symbols in Sake, so they are shown as such here.
KIND = {GetoptLong::AmbiguousOption => :ambiguous_option, GetoptLong::NeedlessArgument => :needless_argument,
        GetoptLong::MissingArgument => :missing_argument, GetoptLong::InvalidOption => :invalid_option}
FLAG = {no_argument: GetoptLong::NO_ARGUMENT, required_argument: GetoptLong::REQUIRED_ARGUMENT,
        optional_argument: GetoptLong::OPTIONAL_ARGUMENT}
ORDER = {permute: GetoptLong::PERMUTE, require_order: GetoptLong::REQUIRE_ORDER, return_in_order: GetoptLong::RETURN_IN_ORDER}
def specs = [["--name", "-n", :required_argument], ["--verbose", "-v", :no_argument],
             ["--level", "-l", :optional_argument], ["--version", :no_argument]]
def conv(specs) = specs.map { |s| s.map { |x| FLAG.fetch(x, x) } }
def kind(e) = KIND[e] || e
def new_parser(argv, specs)
  ARGV.replace(argv)
  GetoptLong.new(*conv(specs))
end

# Parse argv with the standard specs; print the options, the arguments left, and the state.
def run(argv, ordering = nil)
  g = new_parser(argv, specs)
  g.quiet = true
  g.ordering = ORDER.fetch(ordering) if ordering != nil
  out = []
  begin
    g.each { |n, a| out.push([n, a]) }
    puts("#{out.inspect} rest=#{ARGV.inspect} term=#{g.terminated?} err=#{kind(g.error).inspect}")
  rescue GetoptLong::Error => e
    puts("#{kind(e.class)}: #{e.message} rest=#{ARGV.inspect} err=#{kind(g.error).inspect} msg=#{g.error_message.inspect}")
    p(g.get)
  end
end

run(["-n", "foo", "-v", "a", "b"])
run(["a", "-n", "foo", "b", "-v", "c"])
run(["a", "-n", "foo", "b", "-v", "c"], :require_order)
run(["a", "-n", "foo", "b", "-v", "c"], :return_in_order)
run(["--name=bar", "--level", "--verb", "--", "-v", "x"])
run(["--level", "3", "--level", "-v", "-l5", "-vl", "7", "-nx"])
run(["--ver"])
run(["--zzz"])
run(["-z"])
run(["--name"])
run(["-n"])
run(["--verbose=1"])
run(["-vz"])
run(["--name=", "x"])
run(["-"])
run(["-", "-v"], :require_order)
run(["-vn", "foo"])
run(["-nvfoo"])
run(["-l"])
run(["-l", "-v"])
run(["--level="])
run(["--version=2"])
run([])
run(["a", "b"])
run(["-vv"])
run(["--name", "--verbose"])
run(["--name", "--", "x"])
run(["-n", "-v"])
run(["--na", "x"])
run(["--n", "x"])
run(["--version", "--verbose"])
run(["-l=3"])
run(["--level=3=4"])
run(["-vl"])
run(["--", "-v"])
run(["a", "--", "-v"], :return_in_order)
run(["x", "-v", "y", "--", "-n", "z"])

# invalid option lists
def bad(*specs)
  new_parser(["-v"], specs)
  puts("ok")
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end
bad(["--a"])
bad(["--a", "-b", "c", :no_argument])
bad(["--a", :no_argument, :required_argument])
bad([:no_argument])
bad(["--a", :no_argument], ["--a", :required_argument])
bad(["---a", :no_argument])
bad(["--", :no_argument])
bad(["-vv", :no_argument])
bad(["--a", :no_argument], ["-b", :optional_argument])

# get, one option at a time; changing the options after the start
g = new_parser(["-v"], specs)
g.quiet = true
p(g.get)
p(g.get)
p(g.get_option)
p(g.terminated?)
begin
  g.ordering = GetoptLong::PERMUTE
rescue ArgumentError => e
  puts("ArgumentError: #{e.message} #{(g.error == ArgumentError ? :argument_error : g.error).inspect}")
end
begin
  g.set_options(["--x", GetoptLong::NO_ARGUMENT])
rescue RuntimeError => e
  puts("RuntimeError: #{e.message}")
end
p(g.terminate != nil)
begin
  new_parser([], []).ordering = :sideways
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end

# after an error: get gives nil, terminate raises
g = new_parser(["-z"], specs)
g.quiet = true
begin
  g.get
rescue GetoptLong::Error => e
  puts(e.message)
end
begin
  g.terminate
rescue RuntimeError => e
  puts("RuntimeError: #{e.message}")
end
p(g.get)
p([g.quiet?, ORDER.key(g.ordering), kind(g.error), kind(g.error?), g.error_message])

# defaults, set_options after new, each returns the parser, each_option
g2 = new_parser(["--flag", "rest"], [])
p([ORDER.key(g2.ordering), g2.quiet])
g2.set_options(["--flag", "-f", GetoptLong::NO_ARGUMENT], ["-x", GetoptLong::REQUIRED_ARGUMENT])
g2.each_option { |n, a| puts("#{n}=#{a}") }
p(ARGV)
p(g2.terminate != nil)

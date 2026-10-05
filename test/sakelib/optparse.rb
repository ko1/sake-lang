require "optparse"

def build
  op = OptionParser.new
  op.banner = "Usage: tool [options]"
  op.separator("")
  op.separator("Specific options:")
  op.on("-v", "--[no-]verbose", "Run verbosely")
  op.on("-n", "--name NAME", "Name to use")
  op.on("-c", "--count N", Integer, "How many")
  op.on("-r", "--ratio R", Float, "Ratio")
  op.on("-l", "--level [LEVEL]", "Optional level")
  op.on("-t", "--type TYPE", ["text", "binary", "bits"], "Select type")
  op.on("-q", "Quiet")
  op.on("--dry-run", "Dry run")
  op.on("--debug", "Debug")
  op.on("--a-very-long-option-name-here VALUE", "Long one")
  op.on("-x VALUE", "Short with an argument")
  op.on("-u", "--unicode-é", "Ünïcode ✓")
  op.on("--nodesc")
  op.on_tail("-h", "--help", "Show this message")
  op.separator("Common options:")
  op
end

op = build
puts(op.help)
puts("--")
puts(op)
p(op.summary_width)
p(op.summary_indent)

cases = [
  ["-v", "-n", "foo", "a", "b"], ["--no-verbose", "--name=bar", "-c", "3", "x"],
  ["-vq", "-nfoo", "--", "-v"], ["-l"], ["-l", "3", "rest"], ["--level=4"],
  ["--verb", "--dry-"], ["-t", "bin"], ["-xval", "-x", "val2"],
  ["-z"], ["--zzz"], ["--name"], ["-c", "abc"], ["--dry-run=1"], ["--d"],
  ["-c"], ["-c", "0x10"], ["-r", "1e3"], ["-t", "foo"], ["-t", "bi"], ["-"],
  ["x", "-v", "y"], ["--count=-5"], ["-vn"], ["-v", "-n", "-c"], ["--n"],
  ["--na", "x"], ["--no-v"], ["--no-verbose=1"], ["-vz"], ["--no-name", "x"],
  ["--no-dry-run"], ["--de"], ["--level", "-v"], ["-l3"], ["-c", "-5"],
  ["--count="], ["--name="], ["a", "--", "-b"], ["--no-"], ["-c", "1_000"],
  ["-c", "08"], ["-c", "1.5"], ["-cabc"], ["--count", "abc"], ["-r", ".5"],
  ["-r", "x"], ["-u", "--unicode-é", "ü"], ["-h"], [], ["--help", "--nodesc"]
]

def show(h) = "{" + h.map { |k, v| "#{k}: #{v.inspect}" }.join(", ") + "}"

cases.each do |argv|
  h = {}
  begin
    rest = op.parse(argv, into: h)
    puts("#{show(h)} #{rest.inspect}")
  rescue OptionParser::ParseError => e
    puts("#{e.class.name.sub("OptionParser::", "")}: #{e.message} #{e.args.inspect} #{e.reason}")
  end
  h2 = {}
  copy = argv.dup
  begin
    r = op.order!(copy, into: h2)
    puts("#{show(h2)} #{r.inspect} #{copy.inspect}")
  rescue OptionParser::ParseError => e
    puts("order: #{e.message} #{show(h2)}")
  end
end

args = ["-v", "file1", "--name", "n", "file2"]
h = {}
r = op.parse!(args, into: h)
p(r)
p(args)
puts(show(h))

args = ["-a", "-b", "1", "--foo", "--bar=x", "rest"]
p(OptionParser.new.getopts(args, "ab:c", "foo", "bar:", "baz"))
p(args)

plain = OptionParser.new
plain.program_name = "plain"
plain.on("-a")
print(plain.help)

# defaults: parse(argv) without a Hash, ARGV when argv is left out, getopts without long options
p(op.parse(["-v", "a", "-n", "x", "b"]))
p(plain.parse)
p(plain.parse!)
args = ["-a", "x", "-b"]
p(OptionParser.new.getopts(args, "ab"))
p(args)
plain.warn("a warning on stderr")
plain.version = "1.2"
p(plain.ver)
p(op.ver)

# into: as a keyword, as in Ruby
h3 = {}
p(op.permute(["a", "-v", "b"], into: h3))
p(op.order(["-n", "z", "a", "-v"], into: h3))
puts(show(h3))
args = ["x", "--count", "2"]
p(op.permute!(args, into: h3))
puts(show(h3))

# new(banner, width, indent) positionally, on_head, and on with more than four arguments
small = OptionParser.new("Usage: small [opts]", 10, "  ")
small.on("-a", "--all", "All")
small.separator("More:")
small.on_head("-f", "--first", "First, before the separator")
small.on("-k", "--kind K", ["x", "y"], String, "Kind")
small.on("-m", "--multi", "Line one", "line two")
print(small.help)
h4 = {}
p(small.parse(["-f", "-k", "y", "z"], into: h4))
puts(show(h4))

# --help that was not declared: prints the help and exits 0 (abbreviated, as Ruby)
begin
  plain.parse(["-a", "--he"])
ensure
  puts("ensure ran")
end
puts("not reached")

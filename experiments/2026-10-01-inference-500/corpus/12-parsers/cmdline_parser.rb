class Opt
  attr_reader :long, :short, :type, :default, :help

  def initialize(long, short, type, default, help)
    @long = long
    @short = short
    @type = type
    @default = default
    @help = help
  end

  def takes_value? = %i[int string list].include?(@type)
end

class UsageError < StandardError
  attr_reader :arg

  def initialize(message, arg)
    super(message)
    @arg = arg
  end
end

SPEC = [
  Opt.new("verbose", "v", :count, 0, "more output (repeatable)"),
  Opt.new("color", "c", :flag, true, "colorize output"),
  Opt.new("jobs", "j", :int, 1, "parallel jobs"),
  Opt.new("output", "o", :string, "-", "output file"),
  Opt.new("include", "I", :list, nil, "include path (repeatable)"),
  Opt.new("dry-run", "n", :flag, false, "do nothing")
].freeze

def find_long(name) = SPEC.find { |o| o.long == name }
def find_short(ch) = SPEC.find { |o| o.short == ch }

def defaults = SPEC.to_h { |o| [o.long, o.type == :list ? [] : o.default] }

def convert(opt, value, arg)
  return value unless opt.type == :int
  raise UsageError.new("--#{opt.long} needs an integer, got '#{value}'", arg) unless value.match?(/\A-?\d+\z/)
  value.to_i
end

def store(result, opt, value)
  case opt.type
  when :list then result[opt.long] << value
  when :count then result[opt.long] += 1
  else result[opt.long] = value
  end
end

def parse_args(argv)
  result = defaults
  positional = []
  i = 0
  only_positional = false
  while i < argv.size
    arg = argv[i]
    i += 1
    if only_positional || arg == "-" || !arg.start_with?("-")
      positional << arg
    elsif arg == "--"
      only_positional = true
    elsif arg.start_with?("--")
      name, eq, inline = arg[2..].partition("=")
      negated = false
      opt = find_long(name)
      if opt.nil? && name.start_with?("no-")
        opt = find_long(name[3..])
        negated = !opt.nil? && opt.type == :flag
        opt = nil unless negated
      end
      raise UsageError.new("unknown option --#{name}", arg) if opt.nil?
      if opt.takes_value?
        if eq.empty?
          raise UsageError.new("--#{name} needs a value", arg) if i >= argv.size
          inline = argv[i]
          i += 1
        end
        store(result, opt, convert(opt, inline, arg))
      else
        raise UsageError.new("--#{name} does not take a value", arg) unless eq.empty?
        store(result, opt, !negated)
      end
    else
      j = 1
      while j < arg.size
        ch = arg[j]
        opt = find_short(ch)
        raise UsageError.new("unknown option -#{ch}", arg) if opt.nil?
        j += 1
        if opt.takes_value?
          value = arg[j..]
          if value.empty?
            raise UsageError.new("-#{ch} needs a value", arg) if i >= argv.size
            value = argv[i]
            i += 1
          end
          store(result, opt, convert(opt, value, arg))
          j = arg.size
        else
          store(result, opt, true)
        end
      end
    end
  end
  [result, positional]
end

def show(v)
  case v
  when Array then "[" + v.join(", ") + "]"
  when String then v.inspect
  else v.to_s
  end
end

def usage
  lines = SPEC.map do |o|
    left = "-#{o.short}, --#{o.long}"
    left += " VALUE" if o.takes_value?
    format("  %-24s %s", left, o.help)
  end
  "usage: tool [options] FILE...\n" + lines.join("\n")
end

puts usage
argvs = [
  ["build.c", "-vv", "--jobs=4", "-o", "out.bin", "util.c"],
  ["-I", "inc", "-Ilib", "--include", "vendor", "--no-color", "-nv", "main.c"],
  ["-j8", "--output=-", "--", "-weird-file", "--jobs"],
  ["-", "--dry-run", "--verbose", "--verbose"],
  ["--jobs", "many"],
  ["--frobnicate"],
  ["-vx"],
  ["--output"],
  ["--dry-run=yes"],
  ["--no-jobs", "3"]
]
argvs.each do |argv|
  puts "$ tool #{argv.join(" ")}"
  begin
    result, files = parse_args(argv)
    d = defaults
    result.each { |k, v| puts "    #{k.ljust(8)} = #{show(v)}" if v != d[k] }
    puts "    files    = #{show(files)}"
  rescue UsageError => e
    puts "    error: #{e.message} (in '#{e.arg}')"
  end
end

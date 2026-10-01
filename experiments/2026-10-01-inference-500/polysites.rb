# frozen_string_literal: true

# How often a call's receiver has more than one class at run time, in the Ruby versions of the corpus.
# These are the calls that Sake cannot write as a single `T.op(x)`.
# usage: ruby polysites.rb FILE.rb...   (prints one JSON object per program)
#
# A site is (line, method name); calls of one method on one line are merged. Categories of a site
# whose receivers have 2+ classes:
#   operator  an operator or []: already dispatched on the left operand in Sake
#   show      to_s / inspect / == / hash / eql? and friends: Kernel functions in Sake
#   user      every receiver is a class of the program: Sake's module dispatch (M.f(x)) fits
#   builtin   every receiver is a built-in class: the `(String|Array).op(x)` candidates
#   mixed     both
#   exception every receiver is an exception (Exception.message(e) already takes any exception)
# Only calls written with a receiver on that line count (not calls made inside Ruby, such as raise
# calling #exception).
# NilClass in a set is counted separately (nil-receivers are a nil-check matter, not dispatch).
require "json"
require "open3"
require "tmpdir"
require "prism"

# (line, method) of every call written with a receiver in the source; other traced calls are
# internal (raise calling exception/backtrace, puts calling $stdout.puts, ...).
def written_calls(source)
  out = {}
  walk = lambda do |n|
    out["#{n.message_loc&.start_line || n.location.start_line} #{n.name}"] = true if n.is_a?(Prism::CallNode) && n.receiver
    out["#{n.location.start_line} #{n.expression.unescaped}"] = true if n.is_a?(Prism::BlockArgumentNode) && n.expression.is_a?(Prism::SymbolNode) # map(&:size)
    n.compact_child_nodes.each { walk.(_1) }
  end
  walk.(Prism.parse(source).value)
  out
end

OPERATORS = %w[+ - * / % ** == != < <= > >= <=> [] []= << >> & | ^ =~ ! -@ +@ ~ ===].freeze
SHOW = %w[to_s inspect hash eql? equal? frozen? nil? class is_a? respond_to? dup freeze].freeze
TRACER = File.expand_path("tools/receiver_trace.rb", __dir__)

ARGV.each do |path|
  Dir.mktmpdir do |dir|
    out = File.join(dir, "trace.json")
    _, err, st = Open3.capture3({ "RECEIVER_TRACE_OUT" => out }, "ruby", "-r#{TRACER}", path)
    unless st.success? && File.exist?(out)
      puts JSON.generate(path:, error: err.lines.first&.chomp)
      next
    end
    source = File.read(path)
    user = source.scan(/^\s*(?:class|module)\s+([A-Z]\w*)/).flatten.uniq
    errors = source.scan(/^\s*class\s+([A-Z]\w*)\s*<\s*(?:[A-Z]\w*Error|Exception|StandardError)\b/).flatten
    written = written_calls(source)
    sites = JSON.parse(File.read(out))
    found = []
    sites.each do |key, classes|
      line, meth = key.split(" ", 2)
      non_nil = classes - ["NilClass"]
      next if non_nil.size < 2 || !written[key]
      cat =
        if OPERATORS.include?(meth) then "operator"
        elsif non_nil.all? { errors.include?(_1) || _1.end_with?("Error") || _1 == "Exception" } then "exception"
        elsif SHOW.include?(meth) then "show"
        elsif non_nil.all? { user.include?(_1) } then "user"
        elsif non_nil.none? { user.include?(_1) } then "builtin"
        else "mixed"
        end
      found << { line: line.to_i, method: meth, classes: non_nil.sort, with_nil: classes.include?("NilClass"), category: cat }
    end
    counts = found.group_by { _1[:category] }.transform_values(&:size)
    puts JSON.generate(path:, sites: sites.size, poly: counts, found: found.sort_by { _1[:line] })
  end
end

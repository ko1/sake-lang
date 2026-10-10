# frozen_string_literal: true

# Checks the built-in reference chapters, docs/manual/{ja,en}/ref/NS.md, against the registry:
#   - every operation of the namespace has a `## name` section (aliases share one: `## find, detect`),
#     and no section names an operation that does not exist;
#   - each section carries the exact signature line of each of its operations (`Array.first(x, [Integer])`);
#   - every ```ruby block runs clean under --strict=2 (from an empty directory, stdin "3\n1 2\n"),
#     and its stdout equals, line by line, the `# => ...` annotations in the block;
#     a ```ruby error block must be rejected or fail, and each `# !> text` must appear in the output;
#   - the Japanese and English chapters cover the same operations.
# usage: ruby tools/check_reference.rb [NS...]          check (all namespaces when none given)
#        ruby tools/check_reference.rb --list NS         print the operations and signatures of NS
#        ruby tools/check_reference.rb --skeleton NS     print a chapter skeleton for NS
#        ruby tools/check_reference.rb --coverage        one line per namespace: documented / total
require "stringio"
require "open3"
require "tmpdir"
require "etc"
require_relative "../lib/sake"

ROOT = File.expand_path("..", __dir__)
SAKE = File.join(ROOT, "bin/sake")
REF = { "ja" => File.join(ROOT, "docs/manual/ja/ref"), "en" => File.join(ROOT, "docs/manual/en/ref") }.freeze
EXCEPTIONS = "Exceptions" # the chapter of the built-in exception types

def registry
  @registry ||= begin
    reg = Sake::Registry.new
    Sake::Stdlib.install(reg, StringIO.new)
    Sake::Stdlib.install_ext(reg, StringIO.new, StringIO.new)
    reg
  end
end

def namespaces = (registry.namespaces.select { registry.names(_1).any? } + prelude_functions.keys).sort

# The prelude's modules (Enum), written in Sake: namespace => { name => UserFunction }.
def prelude_functions
  @prelude_functions ||= Sake.load("", "check_reference.sake", out: StringIO.new, input: StringIO.new).functions.reject { |ns, _| ns.nil? }
end

# name => signature, the heading name being `Array[]` for the constructor.
def operations(ns)
  if ns == EXCEPTIONS
    named = Sake::Resolver::BUILTIN_EXCEPTIONS.reject { _1.include?("::") }
    return named.to_h { |e| [e, "#{e}.new(message)"] }
  end
  if (fns = prelude_functions[ns])
    return fns.values.sort_by(&:name).to_h do |fn|
      req = fn.params.size - fn.defaults.size
      params = fn.params.each_with_index.map { |p, i| i < req ? p.to_s : "[#{p}]" }
      block = fn.yields ? (fn.block_optional ? " [{ }]" : " { }") : ""
      [fn.name, "#{ns}.#{fn.name}(#{params.join(", ")})#{block}"]
    end
  end
  registry.names(ns).sort.to_h do |n|
    b = registry.lookup(ns, n)
    [n == Sake::CTOR ? "#{ns}[]" : n, b.signature]
  end
end

Section = Struct.new(:names, :line, :body)

def sections(text)
  out = []
  text.each_line.with_index(1) do |l, i|
    if (m = l.match(/\A## (.+)\n\z/))
      out << Section.new(m[1].split(/,\s*/), i, +"")
    elsif out.any?
      out.last.body << l
    end
  end
  out
end

def check_chapter(ns, lang, errors)
  path = File.join(REF[lang], "#{ns}.md")
  return errors << "#{lang}/ref/#{ns}.md: missing" unless File.exist?(path)
  text = File.read(path)
  rel = "#{lang}/ref/#{ns}.md"
  errors << "#{rel}: the first line must be `# #{ns}`" unless text.start_with?("# #{ns}\n")
  ops = operations(ns)
  seen = {}
  secs = sections(text)
  secs.each do |s|
    s.names.each do |n|
      errors << "#{rel}:#{s.line}: `#{n}` is not an operation of #{ns}" unless ops.key?(n)
      errors << "#{rel}:#{s.line}: `#{n}` is documented twice" if seen.key?(n)
      seen[n] = s.line
      sig = ops[n] or next
      errors << "#{rel}:#{s.line}: section `#{n}` lacks the signature line `#{sig}`" unless s.body.include?("`#{sig}`\n")
    end
  end
  (ops.keys - seen.keys).each { errors << "#{rel}: `#{_1}` is not documented (`#{ops[_1]}`)" }
  check_examples(text, rel, errors)
  seen.keys
end

def check_examples(text, rel, errors)
  blocks = []
  text.each_line.with_index(1) do |l, i|
    if (m = l.match(/\A```ruby( error)?\n\z/)) then blocks << [i, !m[1].nil?, +""]
    elsif l.start_with?("```") then blocks.last&.then { _1 << :done unless _1.last == :done } # end of a fence
    elsif blocks.any? && blocks.last.last != :done then blocks.last[2] << l
    end
  end
  Dir.mktmpdir("ref") do |dir|
    blocks.each do |line, error, code|
      path = File.join(dir, "ex.sake")
      File.write(path, code)
      out, err, st = Open3.capture3(RbConfig.ruby, SAKE, "--strict=2", path, stdin_data: "3\n1 2\n", chdir: dir)
      all = out + err
      if error
        errors << "#{rel}:#{line}: the `ruby error` example did not fail:\n#{code}" if st.success?
        code.scan(/# !> (.+)$/).flatten.each do |want|
          errors << "#{rel}:#{line}: the example's output lacks `#{want}`:\n#{all}" unless all.include?(want)
        end
      elsif !st.success? || !err.empty?
        errors << "#{rel}:#{line}: the example fails under --strict=2:\n#{code}--- output ---\n#{all}"
      else
        want = code.scan(/# => (.*)$/).flatten.map(&:rstrip)
        got = out.lines.map(&:chomp)
        next if want.empty?
        next if want == got
        errors << "#{rel}:#{line}: the `# =>` annotations differ from the output:\n#{code}--- expected ---\n#{want.join("\n")}\n--- got ---\n#{got.join("\n")}"
      end
    end
  end
end

def check_namespace(ns)
  errors = []
  covered = REF.keys.to_h { |lang| [lang, check_chapter(ns, lang, errors) || []] }
  only_ja = covered["ja"] - covered["en"]
  only_en = covered["en"] - covered["ja"]
  errors << "#{ns}: only in ja: #{only_ja.join(", ")}" if only_ja.any?
  errors << "#{ns}: only in en: #{only_en.join(", ")}" if only_en.any?
  errors
end

# The chapters are checked JOBS at a time (each example is a `bin/sake` process; the whole
# reference is about 1,500 of them). Every chapter runs its examples in its own temp dir.
def check(nss)
  jobs = Integer(ENV.fetch("JOBS", [Etc.nprocessors, 8].min))
  queue = Queue.new
  nss.each { queue << _1 }
  results = {}
  lock = Mutex.new
  Array.new([jobs, nss.size].min) do
    Thread.new do
      while (ns = queue.pop(true) rescue nil)
        r = check_namespace(ns)
        lock.synchronize { results[ns] = r }
      end
    end
  end.each(&:join)
  nss.flat_map { results.fetch(_1) }
end

def skeleton(ns)
  out = +"# #{ns}\n\n(introduction)\n\n"
  operations(ns).each { |n, sig| out << "## #{n}\n\n`#{sig}`\n\n(description)\n\n```ruby\n```\n\n" }
  out
end

if __FILE__ == $0
  all = namespaces + [EXCEPTIONS]
  case ARGV[0]
  when "--list" then operations(ARGV.fetch(1)).each { |n, sig| puts "#{n}\t#{sig}" }
  when "--skeleton" then puts skeleton(ARGV.fetch(1))
  when "--coverage"
    all.each do |ns|
      n = operations(ns).size
      done = REF.keys.map { |lang| (path = File.join(REF[lang], "#{ns}.md"); File.exist?(path) ? sections(File.read(path)).sum { _1.names.size } : 0) }
      puts format("%-12s %4d ops  ja %4d  en %4d", ns, n, *done)
    end
  else
    nss = ARGV.empty? ? all : ARGV
    unknown = nss - all
    abort "unknown namespaces: #{unknown.join(", ")}" if unknown.any?
    errors = check(nss)
    errors.each { warn _1 }
    puts "#{nss.size} chapters, #{errors.size} problems"
    exit errors.empty? ? 0 : 1
  end
end

# Runs the SQL engine's tests: each tests/<stage>/NNN-*.sql is fed to the program on standard input
# and its standard output is compared with NNN-*.out.
#
#   ruby run_tests.rb MAIN [--steep] [--stage N] [NAME_SUBSTRING...]
#   ruby run_tests.rb MAIN [--steep] --check-only   (P11: only the check; Ruby `ruby -wc`, Scheme reads every form)
#
# MAIN is the program's entry file, and its name says the language:
#   main.rb    Ruby: run with ruby. With --steep, the program is first type-checked with Steep (below).
#   main.sake  Sake: first checked with /home/ko1/app/sake/bin/sake --strict=2 -c, then each test runs
#              at --strict=0 (the level only decides what stops a program before it runs).
#   Main.java  Java: every .java file under MAIN's directory is compiled with javac into a temporary
#              directory, then each test runs `java -cp DIR Main`.
#   Main.hs    Haskell: compiled with `ghc -O1 -i<MAIN's directory>`, then each test runs the binary.
#   main.ss    Chez Scheme: each test runs `scheme --libdirs <MAIN's directory> --program main.ss`
#              with MAIN's directory as the current directory.
# Steep: a Steepfile is generated that checks every .rb file under MAIN's directory against the
# signatures in its sig/ directory with Steep's strict diagnostics, and `steep check` must report no
# problem (warnings included). A signature that says `untyped` and a `steep:ignore` comment also fail
# the check.
# The check or compilation runs once; if it fails, "CHECK FAILED" and its first lines are printed and
# no test runs. --stage N runs the tests of stages 1..N (default: every stage present). With
# substrings, only the tests whose "<stage>/<file name>" contains one of them run. A test fails when
# the output differs, the exit status is not 0, or it runs longer than SQL_TEST_TIMEOUT seconds
# (default 60). Tests run SQL_TEST_JOBS at a time (default 8). SQL_TESTS=DIR takes the tests from DIR
# instead of tests/ (same layout). Exits with status 1 if any test fails.

require "open3"
require "tmpdir"
require "pathname"

DIR = __dir__
SAKE = "/home/ko1/app/sake/bin/sake"

# [check command or nil, test command, working directory or nil]; nil for an unknown entry name.
def plan_for(main, steep, tmp)
  path = File.expand_path(main)
  dir = File.dirname(path)
  case File.basename(path)
  when "main.rb"
    return [nil, ["ruby", path], nil] unless steep
    steepfile = File.join(tmp, "Steepfile")
    rel = Pathname(dir).relative_path_from(Pathname(tmp)).to_s
    File.write(steepfile, <<~STEEP)
      target :engine do
        check #{rel.dump}
        signature #{File.join(rel, "sig").dump}
        configure_code_diagnostics(Steep::Diagnostic::Ruby.strict)
      end
    STEEP
    [["steep", "check", "--steepfile=#{steepfile}"], ["ruby", path], nil]
  when "main.sake" then [[SAKE, "--strict=2", "-c", path], [SAKE, "--strict=0", path], nil]
  when "Main.java"
    sources = Dir.glob(File.join(dir, "**", "*.java")).sort
    [["javac", "-d", File.join(tmp, "classes"), *sources],
     ["java", "-XX:+UseSerialGC", "-XX:TieredStopAtLevel=1", "-cp", File.join(tmp, "classes"), "Main"], nil]
  when "Main.hs"
    [["ghc", "-O1", "-v0", "-outputdir", File.join(tmp, "build"), "-o", File.join(tmp, "main"), "-i#{dir}", path],
     [File.join(tmp, "main")], nil]
  when "main.ss" then [nil, ["scheme", "--libdirs", dir, "--program", path], dir]
  end
end

# --check-only for the languages whose tests have no check: Ruby `ruby -wc` on every file, Scheme reading
# every form of every file (no code runs).
def syntax_check(main_path, tmp)
  dir = File.dirname(File.expand_path(main_path))
  case File.basename(main_path)
  when "main.rb"
    ["ruby", "-e", 'bad = ARGV.reject { system("ruby", "-wc", _1, out: File::NULL) }; bad.each { system("ruby", "-wc", _1) }; exit(bad.empty?)',
     *Dir.glob(File.join(dir, "**", "*.rb")).sort]
  when "main.ss"
    reader = '(for-each (lambda (f) (call-with-input-file f (lambda (p) (let loop () (unless (eof-object? (read p)) (loop)))))) (cdr (command-line)))'
    File.write(File.join(tmp, "read-all.ss"), reader)
    ["scheme", "--script", File.join(tmp, "read-all.ss"), *Dir.glob(File.join(dir, "**", "*.{ss,sls}")).sort]
  end
end

# Steep's check also refuses `untyped` in signatures and steep:ignore comments in the code.
def steep_escapes(dir)
  found = []
  Dir.glob(File.join(dir, "sig", "**", "*.rbs")).each do |f|
    File.foreach(f).with_index(1) { |l, n| found << "#{f}:#{n}: untyped in a signature" if l.sub(/#.*/, "").match?(/\buntyped\b/) }
  end
  Dir.glob(File.join(dir, "**", "*.rb")).each do |f|
    File.foreach(f).with_index(1) { |l, n| found << "#{f}:#{n}: steep:ignore" if l.include?("steep:ignore") }
  end
  found
end

# [stdout, stderr, exit status or nil when it timed out]
def run_one(command, input, timeout, chdir = nil)
  Open3.popen3(*command, **(chdir ? { chdir: } : {})) do |stdin, stdout, stderr, wait|
    out_reader = Thread.new { stdout.read }
    err_reader = Thread.new { stderr.read }
    begin
      stdin.write(input)
    rescue Errno::EPIPE
      # the program exited without reading all of its input; its output still counts
    end
    stdin.close
    unless wait.join(timeout)
      Process.kill("KILL", wait.pid)
      wait.join
      return [out_reader.value, err_reader.value, nil]
    end
    [out_reader.value, err_reader.value, wait.value.exitstatus]
  end
end

# A short description of how `actual` differs from `expected`.
def difference(expected, actual)
  exp_lines = expected.lines
  act_lines = actual.lines
  i = 0
  i += 1 while i < exp_lines.length && i < act_lines.length && exp_lines[i] == act_lines[i]
  "    line #{i + 1}\n" \
    "    expected: #{(exp_lines[i] || "(end of output)").chomp.inspect}\n" \
    "    actual:   #{(act_lines[i] || "(end of output)").chomp.inspect}"
end

def parse_args(args)
  stage = nil
  steep = false
  rest = []
  i = 0
  while i < args.length
    if args[i] == "--stage"
      stage = Integer(args[i + 1])
      i += 2
    elsif args[i] == "--steep"
      steep = true
      i += 1
    elsif args[i] == "--check-only"
      $check_only = true
      i += 1
    else
      rest << args[i]
      i += 1
    end
  end
  [rest[0], steep, stage, rest.drop(1)]
end

def main(args)
  main_path, steep, stage, filters = parse_args(args)
  Dir.mktmpdir("sql-tests") { |tmp| run_tests(main_path, steep, stage, filters, tmp) }
end

def run_tests(main_path, steep, stage, filters, tmp)
  plan = main_path && File.exist?(main_path) && plan_for(main_path, steep, tmp)
  unless plan
    warn("usage: ruby run_tests.rb PATH/{main.rb,main.sake,Main.java,Main.hs,main.ss} [--steep] [--stage N] [NAME_SUBSTRING...]")
    exit(2)
  end
  check, command, chdir = plan
  check ||= syntax_check(main_path, tmp) if $check_only
  if check
    out, err, status = begin
      run_one(check, "", 1200)
    rescue Errno::ENOENT => e
      ["", "#{e.message}\n", 127]
    end
    escapes = steep ? steep_escapes(File.dirname(File.expand_path(main_path))) : []
    unless status == 0 && escapes.empty?
      puts("CHECK FAILED (#{check.first(3).join(" ")} ...): no test run")
      puts((escapes.first(10).map { "#{_1}\n" }.join + out + err).lines.first(30).join)
      exit(1)
    end
  end
  if $check_only
    puts("CHECK OK (#{check.first(3).join(" ")} ...)")
    exit(0)
  end
  timeout = Float(ENV.fetch("SQL_TEST_TIMEOUT", "60"))
  jobs = Integer(ENV.fetch("SQL_TEST_JOBS", "8"))
  tests_dir = ENV.fetch("SQL_TESTS", File.join(DIR, "tests"))
  stages = Dir.children(tests_dir).grep(/\A\d+\z/).map { |s| Integer(s) }.sort
  stages = stages.select { |s| s <= stage } if stage
  tests = stages.flat_map { |s| Dir.glob(File.join(tests_dir, s.to_s, "*.sql")).sort }
  label = ->(path) { "#{File.basename(File.dirname(path))}/#{File.basename(path, ".sql")}" }
  tests = tests.select { |path| filters.any? { |f| label.(path).include?(f) } } unless filters.empty?
  if tests.empty?
    puts("no tests found in #{tests_dir}#{filters.empty? ? "" : " matching #{filters.join(" ")}"}")
    exit(1)
  end

  results = Array.new(tests.length)
  queue = Queue.new
  tests.each_index { |i| queue << i }
  workers = Array.new([jobs, 1].max) do
    Thread.new do
      while (i = (queue.pop(true) rescue nil))
        path = tests[i]
        expected_path = path.sub(/\.sql\z/, ".out")
        unless File.exist?(expected_path)
          results[i] = "MISSING #{label.(path)}: no .out file"
          next
        end
        expected = File.read(expected_path)
        actual, errors, status = run_one(command, File.read(path), timeout, chdir)
        problem =
          if status.nil? then "timed out after #{timeout} seconds"
          elsif status != 0 then "exit status #{status}"
          elsif actual != expected then "output differs"
          end
        next if problem.nil?

        report = +"FAIL #{label.(path)}: #{problem}\n"
        report << difference(expected, actual) << "\n" if actual != expected
        errors.lines.first(5).each { |line| report << "    stderr: #{line.chomp}\n" }
        results[i] = report
      end
    end
  end
  workers.each(&:join)
  failures = results.compact
  failures.each { |r| puts(r) }
  puts("#{tests.length - failures.length} passed, #{failures.length} failed (#{tests.length} tests, #{main_path})")
  exit(failures.empty? ? 0 : 1)
end

main(ARGV)

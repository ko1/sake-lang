# Runs the SQL engine's tests: each tests/<stage>/NNN-*.sql is fed to the program on standard input
# and its standard output is compared with NNN-*.out.
#
#   ruby run_tests.rb MAIN [--stage N] [NAME_SUBSTRING...]
#
# MAIN is the program: a path to main.rb (run with ruby) or main.sake (run with Sake). --stage N runs
# the tests of stages 1..N (default: every stage present). With substrings, only the tests whose
# "<stage>/<file name>" contains one of them run. For Sake the program must first pass
# /home/ko1/app/sake/bin/sake --strict=2 -c, once; then each test runs at --strict=0 (the level only
# decides what stops a program before it runs, not how it runs). A test fails when the output
# differs, the exit status is not 0, or it runs longer than SQL_TEST_TIMEOUT seconds (default 60).
# Tests run SQL_TEST_JOBS at a time (default 8). SQL_TESTS=DIR takes the tests from DIR instead of
# tests/ (same layout). Exits with status 1 if any test fails.

require "open3"

DIR = __dir__
SAKE = "/home/ko1/app/sake/bin/sake"

def command_for(main)
  path = File.expand_path(main)
  return ["ruby", path] if path.end_with?(".rb")
  return [SAKE, "--strict=0", path] if path.end_with?(".sake")
  nil
end

# [stdout, stderr, exit status or nil when it timed out]
def run_one(command, input, timeout)
  Open3.popen3(*command) do |stdin, stdout, stderr, wait|
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
  rest = []
  i = 0
  while i < args.length
    if args[i] == "--stage"
      stage = Integer(args[i + 1])
      i += 2
    else
      rest << args[i]
      i += 1
    end
  end
  [rest[0], stage, rest.drop(1)]
end

def main(args)
  main_path, stage, filters = parse_args(args)
  command = main_path && command_for(main_path)
  if command.nil?
    warn("usage: ruby run_tests.rb PATH/main.rb|PATH/main.sake [--stage N] [NAME_SUBSTRING...]")
    exit(2)
  end
  if main_path.end_with?(".sake")
    out, err, status = run_one([SAKE, "--strict=2", "-c", File.expand_path(main_path)], "", 1200)
    unless status == 0
      puts("CHECK FAILED (#{SAKE} --strict=2 -c): no test run")
      puts((out + err).lines.first(20).join)
      exit(1)
    end
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
        actual, errors, status = run_one(command, File.read(path), timeout)
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

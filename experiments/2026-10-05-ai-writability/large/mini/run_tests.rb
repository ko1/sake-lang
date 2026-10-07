# Runs every tests/NNN-*.mini with an implementation of Mini and compares its
# standard output with tests/NNN-*.out.
#
#   ruby run_tests.rb IMPL [NAME_SUBSTRING...]
#
# IMPL is `ruby` (ruby/main.rb), `sake` (sake/main.sake, the port) or `sake-scratch`
# (sake-scratch/main.sake, written from SPEC.md alone), or a path to any main.rb / main.sake. For Sake the program must first pass
# /home/ko1/app/sake/bin/sake --strict=2 -c, once; then each test runs at --strict=0. With substrings, only the tests whose
# file name contains one of them run. A test fails when the output differs, the
# exit status is not 0, or it runs longer than MINI_TEST_TIMEOUT seconds
# (default 60). MINI_TESTS=DIR runs the tests in DIR instead of tests/. Exits with status 1 if any test fails.

require "open3"

DIR = __dir__
SAKE = "/home/ko1/app/sake/bin/sake"

# IMPL may also be a path to a main.rb / main.sake (the build runs of P6).
def sake_main(impl)
  return File.expand_path(impl) if impl.end_with?(".sake")
  { "sake" => File.join(DIR, "sake", "main.sake"), "sake-scratch" => File.join(DIR, "sake-scratch", "main.sake") }[impl]
end

# Sake checks the whole program once (--strict=2 -c, ~30 s for 2,500 lines) and runs each test with
# --strict=0: the level only decides what stops a program before it runs, not how it runs.
def command_for(impl)
  return ["ruby", File.join(DIR, "ruby", "main.rb")] if impl == "ruby"
  return ["ruby", File.expand_path(impl)] if impl.end_with?(".rb")
  (main = sake_main(impl)) && [SAKE, "--strict=0", main]
end

# [stdout, stderr, exit status or nil when it timed out]
def run_one(command, input, timeout)
  Open3.popen3(*command) do |stdin, stdout, stderr, wait|
    out_reader = Thread.new { stdout.read }
    err_reader = Thread.new { stderr.read }
    stdin.write(input)
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

def main(args)
  impl = args[0]
  command = command_for(impl)
  if command.nil?
    warn("usage: ruby run_tests.rb ruby|sake|sake-scratch|PATH/main.rb|PATH/main.sake [NAME_SUBSTRING...]")
    exit(2)
  end
  if (main = sake_main(impl))
    out, err, status = run_one([SAKE, "--strict=2", "-c", main], "", 600)
    unless status == 0
      puts("CHECK FAILED (#{SAKE} --strict=2 -c): no test run")
      puts((out + err).lines.first(20).join)
      exit(1)
    end
  end
  filters = args.drop(1)
  timeout = Float(ENV.fetch("MINI_TEST_TIMEOUT", "60"))

  tests_dir = ENV.fetch("MINI_TESTS", File.join(DIR, "tests")) # a change task's own suite (changes/mNN-*/tests)
  tests = Dir.glob(File.join(tests_dir, "*.mini")).sort
  tests = tests.select { |path| filters.any? { |f| File.basename(path).include?(f) } } unless filters.empty?
  if tests.empty?
    puts("no tests found in #{tests_dir}#{filters.empty? ? "" : " matching #{filters.join(" ")}"}")
    exit(1)
  end
  failures = 0
  tests.each do |path|
    name = File.basename(path, ".mini")
    expected_path = path.sub(/\.mini\z/, ".out")
    unless File.exist?(expected_path)
      puts("MISSING #{name}: no .out file")
      failures += 1
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

    failures += 1
    puts("FAIL #{name}: #{problem}")
    puts(difference(expected, actual)) if actual != expected
    errors.lines.first(5).each { |line| puts("    stderr: #{line.chomp}") }
  end
  puts("#{tests.length - failures} passed, #{failures} failed (#{tests.length} tests, #{impl})")
  exit(failures == 0 ? 0 : 1)
end

main(ARGV)

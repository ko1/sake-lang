# frozen_string_literal: true

# Golden tests for examples/: every examples/**/NAME.sake that has a NAME.expected next to it is
# run with bin/sake (level 1) and its stdout must equal NAME.expected, with exit status 0.
# NAME.stdin, when present, is fed to the program's standard input (examples/apps/sql/main.stdin).
# UPDATE=1 rewrites the expectations.
require "minitest/autorun"
require "open3"

class TestExamples < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  DIR = File.join(ROOT, "examples")
  SAKE = File.join(ROOT, "bin/sake")

  Dir.glob("**/*.expected", base: DIR).sort.each do |expected|
    base = expected.delete_suffix(".expected")
    define_method("test_#{base.tr("/-", "__")}") do
      sake = File.join(DIR, "#{base}.sake")
      assert File.exist?(sake), "missing #{sake} for #{expected}"
      stdin_path = File.join(DIR, "#{base}.stdin")
      input = File.exist?(stdin_path) ? File.read(stdin_path) : ""
      out, err, st = Open3.capture3(SAKE, File.basename(sake), stdin_data: input, chdir: File.dirname(sake))
      expected_path = File.join(DIR, expected)
      File.write(expected_path, out) if ENV["UPDATE"]
      assert_equal 0, st.exitstatus, "#{base}.sake exited #{st.exitstatus}:\n#{err}"
      assert_equal File.read(expected_path), out, "#{base}.sake: stdout differs from #{expected}"
    end
  end
end

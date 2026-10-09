# frozen_string_literal: true

# The test suite written in Sake (test/sake/*_test.sake, built on sakelib/minitest.sake): each file runs with
# --strict and must exit 0 with a summary of 0 failures and 0 errors.
require "minitest/autorun"
require "open3"

class TestSakeSuite < Minitest::Test
  DIR = File.expand_path("sake", __dir__)
  SAKE = File.expand_path("../bin/sake", __dir__)

  Dir.glob("*_test.sake", base: DIR).sort.each do |file|
    define_method("test_#{File.basename(file, ".sake")}") do
      out, err, st = Open3.capture3(SAKE, "--strict", file, chdir: DIR)
      summary = out.lines.last.to_s
      assert st.success?, "#{file} failed (exit #{st.exitstatus}):\n#{err}\n#{out.lines.last(30).join}"
      assert_match(/\A\d+ runs, \d+ assertions, 0 failures, 0 errors$/, summary, "#{file}: #{summary}")
    end
  end
end

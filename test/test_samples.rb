# frozen_string_literal: true

# Golden tests: each test/samples/NAME.sake is run and compared with NAME.expected
# (stdout, then stderr and exit status). NAME.strict.sake runs with --strict.
# UPDATE=1 rewrites the expectations.
require "minitest/autorun"
require "stringio"
require_relative "../lib/sake/cli"

class TestSamples < Minitest::Test
  DIR = File.expand_path("samples", __dir__)

  def self.render(name)
    out = StringIO.new
    err = StringIO.new
    flags = name.end_with?(".strict") ? ["--strict"] : []
    status = Dir.chdir(DIR) { Sake::CLI.main([*flags, "#{name}.sake"], out:, err:) }
    "#{out.string}--- stderr\n#{err.string}--- exit #{status}\n"
  end

  Dir.glob("*.sake", base: DIR).sort.each do |file|
    name = File.basename(file, ".sake")
    define_method("test_#{name.tr(".", "_")}") do
      actual = self.class.render(name)
      expected_path = File.join(DIR, "#{name}.expected")
      File.write(expected_path, actual) if ENV["UPDATE"]
      assert File.exist?(expected_path), "missing #{expected_path} (run with UPDATE=1)"
      assert_equal File.read(expected_path), actual
    end
  end
end

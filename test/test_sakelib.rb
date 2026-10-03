# frozen_string_literal: true

# Tests of Sake's library (sakelib/): each test/sakelib/NAME.sake runs with --strict (level 2), and its
# output must equal that of NAME.rb, the same program written with Ruby's own library.
require "minitest/autorun"
require "open3"
require "rbconfig"

class TestSakelib < Minitest::Test
  DIR = File.expand_path("sakelib", __dir__)
  SAKE = File.expand_path("../bin/sake", __dir__)

  Dir.glob("*.sake", base: DIR).sort.each do |file|
    name = File.basename(file, ".sake")
    define_method("test_#{name}") do
      out, err, st = Open3.capture3(SAKE, "--strict", file, chdir: DIR)
      assert st.success?, "#{file} failed:\n#{err}"
      rb = File.join(DIR, "#{name}.rb")
      skip "no #{name}.rb to compare with" unless File.exist?(rb)
      expected, rerr, rst = Open3.capture3(RbConfig.ruby, "#{name}.rb", chdir: DIR)
      assert rst.success?, "#{name}.rb failed:\n#{rerr}"
      assert_equal expected, out
    end
  end
end

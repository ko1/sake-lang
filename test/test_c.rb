# frozen_string_literal: true

# The C backend (lib/sake/c.rb, bin/ceec): each test/native/NAME.sake is compiled to a native
# program and run; its stdout must equal what bin/sake prints for the same program (the interpreter is
# the reference). Skipped when cc is not installed.
require "minitest/autorun"
require "open3"
require "tmpdir"

class TestC < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  DIR = File.join(ROOT, "test/native")
  SAKE = File.join(ROOT, "bin/sake")
  CEEC = File.join(ROOT, "bin/ceec")
  HAVE_CC = system(ENV.fetch("CC", "cc"), "--version", out: File::NULL, err: File::NULL)

  Dir.glob("*.sake", base: DIR).sort.each do |file|
    base = file.delete_suffix(".sake")
    define_method("test_#{base}") do
      skip "cc is not installed" unless HAVE_CC
      src = File.join(DIR, file)
      args = File.exist?(File.join(DIR, "#{base}.args")) ? File.read(File.join(DIR, "#{base}.args")).split : []
      want, err, st = Open3.capture3(SAKE, src, *args)
      assert_equal 0, st.exitstatus, "#{file} on the interpreter exited #{st.exitstatus}:\n#{err}"
      Dir.mktmpdir do |tmp|
        exe = File.join(tmp, base)
        out, err, st = Open3.capture3(CEEC, src, "-o", exe)
        assert_equal 0, st.exitstatus, "ceec #{file} exited #{st.exitstatus}:\n#{err}"
        assert_empty err, "the C compiler warned while compiling #{file}:\n#{err}"
        got, err, st = Open3.capture3(exe, *args)
        assert_equal 0, st.exitstatus, "compiled #{file} exited #{st.exitstatus}:\n#{err}"
        assert_equal want, got, "#{file}: the compiled program's stdout differs from the interpreter's"
      end
    end
  end

  def test_unsupported_is_reported_with_the_line
    skip "cc is not installed" unless HAVE_CC
    Dir.mktmpdir do |tmp|
      src = File.join(tmp, "u.sake")
      File.write(src, "h = Hash[a: 1]\nputs(Hash.size(h))\n")
      out, err, st = Open3.capture3(CEEC, src, "--emit", "-o", File.join(tmp, "u"))
      assert_equal 3, st.exitstatus
      assert_match(/u\.sake:1: a Hash literal \(not supported by the C backend\)/, err)
    end
  end

  # Checks the range analysis must not remove: each program fails at run time, as on the interpreter
  # (overflow fails only natively).
  MUST_FAIL = {
    "off_by_one" => "xs = Array.new(3, 0)\ni = 0\nwhile i <= 3\n  puts(Array.fetch(xs, i))\n  i += 1\nend\n",
    "overflow" => "x = 9223372036854775806\ni = 0\nwhile i < 3\n  x += 1\n  i += 1\nend\nputs(x)\n",
    "negative" => "xs = Array.new(3, 0)\ni = 0\nwhile i < 3\n  puts(Array.fetch(xs, i - 4))\n  i += 1\nend\n",
    "closure" => "def twice\n  yield\n  yield\nend\nxs = Array.new(3, 0)\ni = 0\ntwice { i += 5 }\nputs(Array.fetch(xs, i))\n",
  }.freeze

  MUST_FAIL.each do |name, src|
    define_method("test_check_stays_#{name}") do
      skip "the compiler is not installed" unless HAVE_CC
      Dir.mktmpdir do |tmp|
        path = File.join(tmp, "#{name}.sake")
        File.write(path, src)
        _, _, st = Open3.capture3(SAKE, path)
        # The interpreter's Integer has no limit; the native one stops at 64 bits.
        assert_equal 1, st.exitstatus, "#{name}: the interpreter should fail" unless name == "overflow"
        exe = File.join(tmp, name)
        _, err, st = Open3.capture3(CEEC, path, "-o", exe)
        assert_equal 0, st.exitstatus, err
        _, err, st = Open3.capture3(exe)
        refute_equal 0, st.exitstatus, "#{name}: the compiled program should fail like the interpreter"
        assert_match(/IndexError|overflow/, err)
      end
    end
  end
end

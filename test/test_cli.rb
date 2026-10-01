# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"

class TestCLI < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  SAKE = File.join(ROOT, "bin/sake")

  def run_sake(src)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "t.sake")
      File.write(path, src)
      Open3.capture3(SAKE, path)
    end
  end

  # bin/sake gives the program a large thread stack, so recursion is bounded by Sake's own limit.
  def test_deep_recursion
    out, err, st = run_sake("def d(n) = n == 0 ? 0 : 1 + d(n - 1)\np(d(9990))\np(d(10001))\n")
    assert_equal "9990\n", out
    assert_match(/t.sake:1: in d: SystemStackError: stack level too deep/, err)
    assert_match(/\.\.\. \d+ frames omitted \.\.\./, err)
    assert_equal 1, st.exitstatus
  end

  def test_guide_is_up_to_date
    _, _, st = Open3.capture3(RbConfig.ruby, File.join(ROOT, "tools/gen_guide.rb"), "--check")
    assert st.success?, "docs/guide.html is stale; run `ruby tools/gen_guide.rb`"
  end

  def test_tutorial_is_up_to_date
    _, _, st = Open3.capture3(RbConfig.ruby, File.join(ROOT, "tools/gen_tutorial.rb"), "--check")
    assert st.success?, "docs/tutorial.md is stale; run `ruby tools/gen_tutorial.rb`"
  end
end

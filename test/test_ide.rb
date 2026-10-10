# frozen_string_literal: true

# The browser IDE's Ruby side (lib/sake/ide.rb): JSON in, JSON out.
require "minitest/autorun"
require_relative "../lib/sake/ide"

class TestIDE < Minitest::Test
  def call(req) = JSON.parse(Sake::IDE.dispatch(JSON.generate(req)))

  def test_run_reads_stdin_and_reports_status
    r = call(cmd: "run", src: "name = gets\nputs(\"hi \#{name}\")\n", level: 1, stdin: "Sake")
    assert_equal ["hi Sake\n", "", 0], r.values_at("stdout", "stderr", "status")
    r = call(cmd: "run", src: "p(1 + \"a\")\n", level: 1, stdin: "")
    assert_equal 2, r["status"]
    assert_match(/main\.sake:1:/, r["stderr"])
  end

  def test_analyze_gives_errors_at_the_level_and_warnings_above_it
    # One construction site, so the type shows as `Node`; nil reaches `next` through the loop.
    src = "Node = Struct.new(:value, :next)\ndef second(n) = Node.value(Node.next(n))\nhead = nil\n" \
          "Array.each(Array[2, 1]) { |v| head = Node.new(v, head) }\np(second(head)) if head\n"
    r = call(cmd: "analyze", src:, level: 1)
    d = r["diagnostics"].first
    assert_equal ["warning", 2, 2], d.values_at("severity", "level", "line")
    assert_equal [{ "name" => "second", "line" => 2, "params" => [%w[n Node]], "returns" => "Integer" }], r["functions"]
    assert(r["hovers"].any? { _1["type"] == "nil | Node" })
  end

  def test_analyze_shows_only_the_editor_file
    r = call(cmd: "analyze", src: "require \"json\"\np(JSON.generate(Hash[a: 1]))\n", level: 4)
    assert(r["diagnostics"].all? { _1["line"] <= 2 })
    assert(r["hovers"].all? { _1["from"][0] <= 2 })
    assert_empty r["functions"]
  end

  def test_analyze_static_errors_and_symbols
    r = call(cmd: "analyze", src: "Point = Struct.new(:x, :y)\nputs(String.upcse(\"a\"))\n", level: 1)
    assert_equal ["error", 2, 12], r["diagnostics"].first.values_at("severity", "line", "col")
    assert_nil r["ast"]
    assert_equal %w[x y], r["symbols"]["types"]["Point"]["fields"]
  end

  def test_catalog_lists_named_operations
    c = call(cmd: "catalog")
    names = c["namespaces"]["Array"].map { _1["name"] }
    assert_includes names, "sum"
    refute_includes names, "+"
    # The start value is Any since dbeb3963: a type that includes Arithmetic is summed with its own +.
    assert_equal "Array.sum(x, [Any]) [{ }]", c["namespaces"]["Array"].find { _1["name"] == "sum" }["signature"]
  end
end

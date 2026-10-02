# frozen_string_literal: true

# Summarizes out/local.jsonl (see local.rb) as Markdown.
require "json"
rows = File.readlines(ARGV[0] || "out/local.jsonl").map { JSON.parse(_1) }
failed = rows.select { _1["error"] }
rows -= failed
params = rows.flat_map { |r| r["params"].map { _1.merge("path" => r["path"]) } }
called = params.reject { _1["seen"].empty? }
kinds = %w[one union any none]
pct = ->(n, d) { d.zero? ? "-" : format("%.1f%%", 100.0 * n / d) }
puts "## A. Parameter requirements from each function's body alone"
puts
puts "#{rows.size} programs (#{failed.size} failed to analyze); #{params.size} parameters, #{called.size} of them reached when the program runs."
puts
puts "| requirement | all parameters | reached at run time |"
puts "|---|---|---|"
kinds.each { |k| puts "| #{k} | #{params.count { _1["kind"] == k }} (#{pct.(params.count { _1["kind"] == k }, params.size)}) | #{called.count { _1["kind"] == k }} (#{pct.(called.count { _1["kind"] == k }, called.size)}) |" }
puts
unions = params.select { _1["kind"] == "union" }
puts "Union sizes: #{unions.map { _1["size"] }.tally.sort.map { |s, n| "#{s}: #{n}" }.join(", ")}"
puts
puts "Most common unions:"
unions.map { _1["req"].join("|") }.tally.sort_by { -_2 }.first(8).each { |k, n| puts "- `#{k}` #{n}" }
exact = called.count { _1["kind"] != "any" && _1["req"].sort == _1["seen"].map { |s| s == "Record" ? s : s }.sort }
puts
puts "Reached parameters whose requirement equals the set of types they get at run time: #{exact} of #{called.size} (#{pct.(exact, called.size)})."
bad = params.reject { _1["bad"].empty? }
puts "Instrument check: run-time types outside the derived requirement: #{bad.size} parameters."
bad.first(10).each { puts "- #{_1["path"].sub(%r{.*/corpus-v2/}, "")} #{_1["fn"]}##{_1["i"]}: requirement #{_1["req"]&.join("|")}, got #{_1["bad"].join("|")}" }
lo = rows.flat_map { |r| r["local_only_errors"].map { "#{r["path"].sub(%r{.*/corpus-v2/}, "")} #{_1}" } }
puts
puts "Errors found only by the local analysis (code the whole-program typer never reaches): #{lo.size}"
lo.first(10).each { puts "- #{_1}" }
puts
puts "## B. Without the fixpoint over fields and elements (unknown unless declared)"
puts
tot = ->(key) { rows.each_with_object(Hash.new(0)) { |r, h| r[key].each { |k, v| h[k] += v } } }
f = tot.("checks_full")
l = tot.("checks_local")
decided = ->(h) { h["proven"] + h["partial"] + h["error"] }
all = ->(h) { decided.(h) + h["unknown"] }
puts "| | whole program | fields and elements unknown |"
puts "|---|---|---|"
puts "| checks decided (proven / may fail / fails) | #{decided.(f)} of #{all.(f)} (#{pct.(decided.(f), all.(f))}) | #{decided.(l)} of #{all.(l)} (#{pct.(decided.(l), all.(l))}) |"
puts "| proven | #{f["proven"]} | #{l["proven"]} |"
puts "| unknown | #{f["unknown"]} | #{l["unknown"]} |"
%w[1 2].each do |lv|
  puts "| correct programs rejected at level #{lv} | #{rows.count { _1["reject"]["full"][lv] }} | #{rows.count { _1["reject"]["local"][lv] }} |"
end

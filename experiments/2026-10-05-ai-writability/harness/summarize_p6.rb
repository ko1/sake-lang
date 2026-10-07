# frozen_string_literal: true

# P6 summary: ruby harness/summarize_p6.rb runs/usage-p6.tsv runs/grade-p6-*.jsonl
# Per codebase (ruby, sake = the port, sake-scratch), over 8 changes x 2 repetitions:
#   solved (every hidden test passes; Sake also passes --strict=2), hidden tests passed, regressions
#   (kept tests broken), new tests failed, missed functions (reference touched them, the solution did not),
#   lines changed, harness runs, check failures, output tokens and time per agent.
# Then per kind of change: type/shape (m01-m04), syntax (m05-m06), behaviour only (m07-m08).
require "json"

usage_f, *grade_fs = ARGV
rows = grade_fs.flat_map { |f| File.readlines(f).map { JSON.parse(_1) } }
usage = File.readlines(usage_f).drop(1).to_h { |l| r = l.chomp.split("\t"); [r[0], { out: Integer(r[2]), wall: Integer(r[5]), calls: Integer(r[1]) }] }
agent = ->(r) { "#{r["run"]}-#{r["task"]}" }
KIND = { "m01" => "type/shape", "m02" => "type/shape", "m03" => "type/shape", "m04" => "type/shape",
         "m05" => "syntax", "m06" => "syntax", "m07" => "behaviour", "m08" => "behaviour" }.freeze
CBS = %w[ruby sake sake-scratch].freeze

def mean(xs) = xs.empty? ? 0 : xs.sum.fdiv(xs.size)

def line(label, rs, usage, agent)
  us = rs.map { |r| usage.fetch(agent.(r)) { abort "no usage for #{agent.(r)}" } }
  format("%-14s n=%2d solved %2d  hidden %d/%d  regress %d (%d runs)  new-failed %d (%d runs)  missed %d (%d runs)  " \
         "diff %.0f  suite %.1f  single %.1f  check-fail %d  out/agent %.0fk  wall %.1f min",
         label, rs.size, rs.count { _1["ok"] }, rs.sum { _1["passed"] }, rs.sum { _1["total"] },
         rs.sum { _1["regressions"].size }, rs.count { _1["regressions"].any? },
         rs.sum { _1["new_failed"].size }, rs.count { _1["new_failed"].any? },
         rs.sum { _1["missed"].size }, rs.count { _1["missed"].any? },
         mean(rs.map { _1["diff_lines"] }), mean(rs.map { _1["suite_runs"] }), mean(rs.map { _1["single_runs"] }),
         rs.sum { _1["check_failures"] }, mean(us.map { _1[:out] }) / 1000.0, mean(us.map { _1[:wall] }) / 60.0)
end

puts "## per codebase (8 changes x 2 reps)"
CBS.each { |cb| puts line(cb, rows.select { _1["codebase"] == cb }, usage, agent) }
puts "\n## per kind of change and codebase"
%w[type/shape syntax behaviour].each do |k|
  CBS.each { |cb| puts line("#{k[0, 5]} #{cb}", rows.select { _1["codebase"] == cb && KIND[_1["task"][0, 3]] == k }, usage, agent) }
end
puts "\n## per change: solved (of 2) ruby / sake / sake-scratch, and missed functions"
rows.group_by { _1["task"] }.sort.each do |t, rs|
  cells = CBS.map { |cb| x = rs.select { _1["codebase"] == cb }; "#{x.count { _1["ok"] }}/#{x.size}" }
  missed = CBS.map { |cb| rs.select { _1["codebase"] == cb }.flat_map { _1["missed"] }.tally.map { |d, n| "#{d}x#{n}" }.join(" ") }
  puts "#{t.ljust(24)} #{cells.join(" / ")}   missed: #{missed.map { _1.empty? ? "-" : _1 }.join(" | ")}"
end
puts "\n## not solved: what failed"
rows.reject { _1["ok"] }.sort_by { [_1["task"], _1["codebase"], _1["run"]] }.each do |r|
  puts "#{r["run"]} #{r["task"]}: #{r["passed"]}/#{r["total"]} check_ok=#{r["check_ok"]} regress=#{r["regressions"].size} " \
       "new_failed=#{r["new_failed"].size} missed=#{r["missed"].join(",")}#{r["check_diag"] ? " check: #{r["check_diag"].lines.first.to_s.strip[0, 120]}" : ""}"
end
puts "\n## check failures during the work (Sake), first error of each"
rows.select { _1["check_failures"] > 0 }.each do |r|
  puts "#{r["run"]} #{r["task"]}: #{r["check_failures"]} — #{r["check_errors"].map { _1.empty? ? "(no error line: timeout?)" : _1 }.uniq.first(3).join(" | ")}"
end

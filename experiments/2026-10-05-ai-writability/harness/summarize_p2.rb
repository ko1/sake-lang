# frozen_string_literal: true

# P2 summary: ruby harness/summarize_p2.rb  (reads runs/grade-p2*.jsonl, runs/usage-p2.tsv, attempts)
require "json"
Dir.chdir(File.expand_path("..", __dir__))
grades = Dir["runs/grade-p2*.jsonl"].flat_map { |f| File.readlines(f).map { JSON.parse(_1) } }
cond = ->(r) { r["run"].sub(/-r\d\z/, "") }
puts "## accuracy (r2 + r3, 20 tasks each)"
grades.select { _1["run"] =~ /-r[23]\z/ }.group_by(&cond).sort.each do |k, g|
  per = g.group_by { _1["run"] }.transform_values { |x| x.count { _1["ok"] } }
  printf("%-20s solved %s  mean %.1f/20  cases %d/%d  attempts(mean) %.2f\n", k, per.values.inspect, per.values.sum.fdiv(per.size),
         g.sum { _1["passed"] }, g.sum { _1["total"] }, g.sum { _1["attempts"].to_i }.fdiv(g.size))
end
grades.reject { _1["run"] =~ /-r[23]\z/ }.group_by { _1["run"] }.sort.each do |k, g|
  printf("%-24s solved %2d/%d  cases %d/%d  attempts(mean) %.2f\n", k, g.count { _1["ok"] }, g.size, g.sum { _1["passed"] }, g.sum { _1["total"] },
         g.sum { _1["attempts"].to_i }.fdiv(g.size))
end
puts "\n## per task: solved count over r2+r3 (max 2) — sake-agentic sake-oneshot ruby-agentic ruby-oneshot"
grades.select { _1["run"] =~ /-r[23]\z/ }.group_by { _1["task"] }.sort.each do |t, g|
  c = %w[sake-agentic sake-oneshot ruby-agentic ruby-oneshot].map { |k| g.count { |r| r["run"].include?(k) && r["ok"] } }
  puts "#{t.ljust(22)} #{c.join(" ")}"
end
puts "\n## usage per agent (mean over agents)"
us = File.readlines("runs/usage-p2.tsv").drop(1).map { |l| r = l.chomp.split("\t"); [r[0], *r[1..].map(&:to_f)] }
us.group_by { |r| r[0].sub(/-g\d\z/, "").sub(/-r\d/, "-rep") }.sort.each do |k, rs|
  n = rs.size.to_f
  tasks = k =~ /n(10|20)/ ? $1.to_i : 5
  printf("%-24s agents %d tasks/agent %2d  calls %4.1f  out %6.0f  final_ctx %7.0f  input %8.0f  wall %4.0fs  | per task: out %5.0f wall %3.0fs\n",
         k, rs.size, tasks, *[1, 2, 3, 4, 5].map { |i| rs.sum { _1[i] } / n }, rs.sum { _1[2] } / n / tasks, rs.sum { _1[5] } / n / tasks)
end
puts "\n## what stopped Sake attempts before running (agentic, P2)"
Dir["runs/p2-sake-agentic*/*/attempts.jsonl"].flat_map { |f| File.readlines(f).map { JSON.parse(_1) } }.reject { _1["check_ok"] }
  .map { _1["diagnostics"].lines.grep(/error:/).first.to_s.sub(/^.*?error: /, "").sub(/`[^`]*`/, "`…`")[0, 70] }.tally.sort_by { -_2 }.each { puts "#{_2.to_s.rjust(3)} #{_1}" }

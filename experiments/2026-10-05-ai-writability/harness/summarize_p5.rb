# frozen_string_literal: true

# P5 summary (reading): ruby harness/summarize_p5.rb runs/grade-p5.jsonl runs/usage-p5.tsv runs/tool-audit-p5.jsonl
#   predict: exact answers per case, and the share of output lines right; also without the "assisted" tasks
#            (a task named by a shell command that can compute, e.g. printf with a field width; tool_audit.rb).
#   fix:     hidden tests passed, the bug's line touched, lines changed.
#   paired:  the same task, case and repetition in both languages: how often only one of them is right.
#   tokens:  output tokens per agent (usage.rb) / 5 tasks.
require "json"

grade_f, usage_f, audit_f = ARGV
rows = File.readlines(grade_f).map { JSON.parse(_1) }
rep = ->(r) { r["run"][/r\d+\z/] }
assisted = File.readlines(audit_f).map { JSON.parse(_1) }.flat_map do |a|
  a["tasks"].map { |t| [a["agent"].sub(/-g\d+\z/, ""), t] }
end.uniq
is_assisted = ->(r) { assisted.include?([r["run"], r["task"][0, 3]]) }

puts "## predict: exact cases (of 80 = 20 tasks x 2 cases x 2 reps), output lines right"
pred = rows.select { _1["kind"] == "predict" }
%w[sake ruby].each do |l|
  rs = pred.select { _1["lang"] == l }
  cs = rs.flat_map { _1["cases"] }
  clean = rs.reject(&is_assisted)
  ccs = clean.flat_map { _1["cases"] }
  printf("%-5s exact %2d/%d  lines %d/%d (%.1f%%)  unanswered %d | without assisted tasks: exact %d/%d (%d tasks dropped)\n", l,
         cs.count { _1["exact"] }, cs.size, cs.sum { _1["lines_ok"] }, cs.sum { _1["lines"] },
         100.0 * cs.sum { _1["lines_ok"] } / cs.sum { _1["lines"] }, cs.count { !_1["answered"] },
         ccs.count { _1["exact"] }, ccs.size, rs.size - clean.size)
end
by = pred.to_h { |r| [[r["lang"], r["task"], rep.(r)], r] }
both = only_s = only_r = none = 0
pred.select { _1["lang"] == "sake" }.each do |s|
  r = by.fetch(["ruby", s["task"], rep.(s)])
  s["cases"].zip(r["cases"]).each do |cs, cr|
    if cs["exact"] && cr["exact"] then both += 1
    elsif cs["exact"] then only_s += 1
    elsif cr["exact"] then only_r += 1
    else none += 1
    end
  end
end
puts "paired cases: both #{both}, only Sake #{only_s}, only Ruby #{only_r}, neither #{none}"

puts "\n## fix: solved (of 40), bug line touched, lines changed (mean)"
fix = rows.select { _1["kind"] == "fix" }
%w[sake ruby].each do |l|
  rs = fix.select { _1["lang"] == l }
  printf("%-5s solved %2d/%d  touched %2d/%d  diff %.1f  solved-without-checker %d\n", l, rs.count { _1["ok"] }, rs.size,
         rs.count { _1["touched_bug_line"] }, rs.size, rs.sum { _1["diff_lines"] }.fdiv(rs.size), rs.count { _1["ok_without_checker"] })
end
fix.reject { _1["ok"] }.each do |r|
  puts "  failed: #{r["run"]} #{r["task"]} #{r["passed"]}/#{r["total"]} touched=#{r["touched_bug_line"]} diff=#{r["diff_lines"]}"
end

puts "\n## output tokens per task (agent total / 5)"
us = File.readlines(usage_f).drop(1).map { _1.chomp.split("\t") }
us.group_by { _1[0][/p5-(\w+-\w+)-r/, 1] }.sort.each do |k, g|
  outs = g.map { Integer(_1[2]) }
  printf("%-14s agents %d  out/task %5d  (per agent %d..%d)  wall/task %.0fs\n", k, g.size, outs.sum / g.size / 5, outs.min, outs.max,
         g.sum { Integer(_1[5]) }.fdiv(g.size * 5))
end

puts "\n## predict per task: exact cases (of 4) sake / ruby"
pred.group_by { _1["task"] }.sort.each do |t, rs|
  f = ->(l) { rs.select { _1["lang"] == l }.sum { |r| r["cases"].count { _1["exact"] } } }
  puts "#{t.ljust(22)} #{f.("sake")} / #{f.("ruby")}"
end

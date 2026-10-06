# frozen_string_literal: true

# P3 summary (visible results only): ruby harness/summarize_p3.rb USAGE.tsv GRADE.jsonl...
#   USAGE.tsv from usage.rb (one line per agent, named RUN-gN); GRADE.jsonl from grade.rb.
#   A condition is a run name without -rN.
# Per task: solved, try.rb runs, runs stopped by the checker (and why), calls to APIs that do not exist
# (apis.rb on the final solution and on every attempt), run-time NoMethodError/NameError, and for change
# tasks (P4) the lines changed from the starting program (diff/task).
# Output tokens per agent only: agents read and write several tasks in one call, so they do not split by task.
# Anything that cannot be measured aborts instead of being counted as 0.
require_relative "common"
require_relative "apis"
require "set"

Dir.chdir(AW::EXP)
usage_file, *grade_files = ARGV
abort "usage: summarize_p3.rb USAGE_TASK.tsv GRADE.jsonl..." if grade_files.empty?
agent_out = File.readlines(usage_file).drop(1).to_h { |l| r = l.chomp.split("\t"); [r[0], Integer(r[2])] } # agent => output tokens

# The checker's first complaint, as a kind: its item tag ([type], [nil], ...) or the level-0 kind.
def kind(diag)
  line = diag.lines.grep(/error:/).first or return "other"
  msg = line.sub(/^.*?error: /, "")
  return Regexp.last_match(1) if msg =~ /\[([a-z-]+)\]\s*\z/
  case msg
  when /\Asyntax error/ then "syntax"
  when /\Aundefined (function|type or module|local variable)/ then "undefined-name"
  when /\Amethod call on a value/ then "call-on-value"
  when /arguments?|arity/ then "arguments"
  when /has fields besides message/ then "raise-form"
  else "other(#{msg[0, 40].strip})"
  end
end

def check_kind(file, strict)
  out, err, st = AW.run(AW.check_cmd(file, strict), "")
  st == 0 ? nil : kind(out + err)
end

NAME_ERR = /NoMethodError|NameError|undefined method|undefined local variable/
rows = grade_files.flat_map { |f| File.readlines(f).map { JSON.parse(_1) } }.map do |g|
  work = g.fetch("work").sub(%r{\A.*?runs/}, "runs/")
  sol = Dir[File.join(work, "solution.{sake,rb}")].first
  atts = File.exist?(f = File.join(work, "attempts.jsonl")) ? File.readlines(f).map { JSON.parse(_1) } : []
  afiles = Dir[File.join(work, "attempt-*.{sake,rb}")].sort
  abort "#{work}: #{afiles.size} attempt files, #{atts.size} log lines" if afiles.size != atts.size
  rejected = if g["mode"] == "agentic" then atts.reject { _1["check_ok"] }.map { kind(_1["diagnostics"]) }
             else [sol && check_kind(sol, g["strict"])].compact
             end
  api = sol ? APIs.send(g["lang"], sol) : nil
  api_att = afiles.map { APIs.send(g["lang"], _1) }
  { cond: g["run"].sub(/-r\d+\z/, ""), run: g["run"], task: g["task"], lang: g["lang"], mode: g["mode"], ok: g["ok"],
    passed: g["passed"], total: g["total"], tries: atts.size, rejected:, diff: g["diff_lines"],
    api_final: api, api_attempts: api_att,
    name_err_runtime: atts.count { |a| a["examples"].any? { _1["stderr"].match?(NAME_ERR) } } +
      (g["failures"] || []).count { _1["err"].to_s.match?(NAME_ERR) } }
end

def sum_nn(xs, k) = (bad = xs.count { _1.nil? || _1[k].nil? }).zero? ? xs.sum { _1[k] } : "#{xs.sum { _1&.dig(k).to_i }}+#{bad}unparsed"

puts "# P3 summary (#{rows.size} task runs)\n\n"
puts %w[condition runs tasks solved cases tries/task rejected nowhere(final) elsewhere(final) nowhere(attempts) elsewhere(attempts)
        name-err(run) agents out/agent out/task diff/task].join("\t")
rows.group_by { _1[:cond] }.sort.each do |cond, rs|
  outs = agent_out.select { |a, _| rs.any? { |r| a.sub(/-g\d+\z/, "") == r[:run] } }.values
  abort "#{cond}: no agents in #{usage_file}" if outs.empty?
  atts = rs.flat_map { _1[:api_attempts] }
  puts [cond, rs.map { _1[:run] }.uniq.size, rs.size, rs.count { _1[:ok] }, "#{rs.sum { _1[:passed] }}/#{rs.sum { _1[:total] }}",
        rs.first[:mode] == "agentic" ? format("%.2f", rs.sum { _1[:tries] }.fdiv(rs.size)) : "-",
        rs.sum { _1[:rejected].size }, sum_nn(rs.map { _1[:api_final] }, :nowhere),
        rs.first[:lang] == "sake" ? sum_nn(rs.map { _1[:api_final] }, :elsewhere) : "-",
        sum_nn(atts, :nowhere), rs.first[:lang] == "sake" ? sum_nn(atts, :elsewhere) : "-",
        rs.sum { _1[:name_err_runtime] }, outs.size, outs.sum / outs.size, outs.sum / rs.size,
        rs.all? { _1[:diff] } ? format("%.1f", rs.sum { _1[:diff] }.fdiv(rs.size)) : "-"].join("\t")
end
puts "\n## rejected by the checker, by kind (agentic: every try.rb run; oneshot: the final solution)"
rows.group_by { _1[:cond] }.sort.each do |cond, rs|
  t = rs.flat_map { _1[:rejected] }.tally.sort_by { -_2 }
  puts "#{cond}: #{t.empty? ? "none" : t.map { "#{_1} #{_2}" }.join(", ")}"
end
puts "\n## calls to APIs that do not exist (file: names)"
rows.each do |r|
  ([[r[:api_final], "solution"]] + r[:api_attempts].each_with_index.map { [_1, format("attempt-%02d", _2 + 1)] }).each do |a, label|
    puts "#{r[:run]}/#{r[:task]} #{label}: #{a[:names].join(", ")}" if a && a[:names].any?
  end
end
puts "\n## per task: solved / tasks (all conditions in column order)"
conds = rows.map { _1[:cond] }.uniq.sort
puts ["task", *conds].join("\t")
rows.group_by { _1[:task] }.sort.each do |t, rs|
  puts [t, *conds.map { |c| x = rs.select { _1[:cond] == c }; "#{x.count { _1[:ok] }}/#{x.size}" }].join("\t")
end
puts "\n## per task run (TSV)"
puts %w[run task ok passed total tries rejected nowhere elsewhere].join("\t")
rows.each do |r|
  puts [r[:run], r[:task], r[:ok], r[:passed], r[:total], r[:tries], r[:rejected].join(","), r[:api_final]&.dig(:nowhere).inspect,
        r[:api_final]&.dig(:elsewhere).inspect].join("\t")
end

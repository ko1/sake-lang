# frozen_string_literal: true

# P10 summary: per run and stage, the hidden and public results (runs/grade-p10.jsonl, last line per
# run+stage), lines of code, output tokens and working time (runs/usage-p10.tsv), and from each
# agent's transcript:
#   test_runs  - shell commands that ran run_tests.rb with ruby (reading the file, e.g. with cat, is not a run)
#   checks     - other shell commands that ran a checker or compiler on their own: bin/sake at a checking
#                level (-c, or a run without --strict=0; --strict=1 and 2 check the whole program before
#                running it), javac, ghc, or steep
#   rejected   - command results in which the checker or compiler rejected a program: run_tests.rb's
#                "CHECK FAILED", or a diagnostic line in the output ("<f>.sake:L:C: error:",
#                "<f>.java:L: error:", "<f>.hs:L:C: error", "<f>.rb:L:C: [error]" or "[warning]" from
#                Steep). Chez Scheme has no checker; its errors appear when a test runs.
#   test_secs  - wall time between each test-running command and its result, summed (includes queueing
#                on a shared machine)
#   ruby harness/summarize_p10.rb [TRANSCRIPT_DIR]
require "json"
require "time"

EXP = File.expand_path("..", __dir__)
tdir = ARGV[0] || "/tmp/claude-1000/-home-ko1-app-sake/6559df28-cdd4-485b-9a5b-c11baf5a0519/tasks"

grades = {}
File.foreach(File.join(EXP, "runs", "grade-p10.jsonl")) do |l|
  r = JSON.parse(l)
  grades[[r["run"], r["stage"]]] = r
end
usage = {}
File.readlines(File.join(EXP, "runs", "usage-p10.tsv")).drop(1).each do |l|
  name, _calls, out, _ctx, _inp, wall = l.chomp.split("\t")
  usage[name] = { out: Integer(out), wall: Integer(wall) }
end
agents = File.readlines(File.join(EXP, "runs", "agents-p10.tsv")).drop(1).map { _1.chomp.split("\t") }

def transcript_stats(path)
  calls = {}
  stats = { test_runs: 0, checks: 0, rejected: 0, test_secs: 0.0 }
  File.foreach(path) do |l|
    m = JSON.parse(l) rescue next
    msg = m["message"] or next
    content = msg["content"]
    next unless content.is_a?(Array)
    t = m["timestamp"] && Time.parse(m["timestamp"])
    content.each do |c|
      if c["type"] == "tool_use" && c["name"] == "Bash"
        cmd = c.dig("input", "command").to_s
        sake_lines = cmd.lines.flat_map { _1.split(/[|;&]+/) }.grep(%r{bin/sake\b})
        kind = if cmd.match?(/\bruby\s+(-\S+\s+)*\S*run_tests\.rb\b/) then :test
               elsif sake_lines.any? { !_1.include?("--strict=0") || _1 =~ /\s-c\b/ } then :check
               elsif cmd.match?(/(^|[\s;&|(])(javac|ghc|steep)\s/) then :check
               end
        calls[c["id"]] = [kind, t] if kind
      elsif c["type"] == "tool_result" && (k = calls[c["tool_use_id"]])
        text = c["content"].is_a?(Array) ? c["content"].map { _1["text"].to_s }.join : c["content"].to_s
        kind, t0 = k
        stats[kind == :test ? :test_runs : :checks] += 1
        stats[:test_secs] += (t - t0) if kind == :test && t && t0
        rej = text.include?("CHECK FAILED") ||
              text.match?(/\.sake:\d+:\d+: error:|\.java:\d+: error:|\.hs:\d+:\d+: error|\.rb:\d+:\d+: \[(error|warning)\]/)
        stats[:rejected] += 1 if rej
      end
    end
  end
  stats
end

rows = agents.map do |run, stage, id|
  g = grades[[run, Integer(stage)]] or abort "no grade for #{run} stage #{stage}"
  u = usage["#{run}-s#{stage}"] or abort "no usage for #{run}-s#{stage}"
  s = transcript_stats(File.join(tdir, "#{id}.output"))
  { run:, stage: Integer(stage), lines: g["lines"], files: g["files"],
    hidden: "#{g["hidden_pass"]}/#{g["hidden_total"]}", public: "#{g["public_pass"]}/#{g["public_total"]}",
    out_k: (u[:out] / 1000.0).round(1), min: (u[:wall] / 60.0).round(1), **s, test_secs: s[:test_secs].round }
end.sort_by { [_1[:run], _1[:stage]] }

cols = %i[run stage files lines public hidden out_k min test_runs test_secs checks rejected]
puts cols.join("\t")
rows.each { |r| puts cols.map { r[_1] }.join("\t") }
puts
puts "per language (sum over stages, mean over the two runs):"
rows.group_by { _1[:run][/\Ap10-(\w+)-\d+\z/, 1] or abort "run name #{_1[:run]}" }.each do |lang, rs|
  n = rs.map { _1[:run] }.uniq.length
  final = rs.select { _1[:stage] == 6 }
  puts format("%-5s out %.0fk  time %.0f min  test runs %.0f  test wait %.0f min  checks %.0f  rejected %.0f  final lines %s  final hidden %s",
              lang, rs.sum { _1[:out_k] } / n, rs.sum { _1[:min] } / n, rs.sum { _1[:test_runs] }.to_f / n,
              rs.sum { _1[:test_secs] } / 60.0 / n, rs.sum { _1[:checks] }.to_f / n, rs.sum { _1[:rejected] }.to_f / n,
              final.map { _1[:lines] }.join("/"), final.map { _1[:hidden] }.join(" "))
end

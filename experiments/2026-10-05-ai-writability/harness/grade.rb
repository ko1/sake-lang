# frozen_string_literal: true

# Grades solutions on the hidden tests: ruby grade.rb WORK_DIR...  (each has meta.json and solution.*)
# Prints one JSON line per work dir. A missing solution is a failure, never a pass.
require_relative "common"

ARGV.each do |work|
  meta = JSON.parse(File.read(File.join(work, "meta.json")))
  sol = Dir[File.join(work, "solution.{sake,rb}")].first
  task_dir = File.join(AW::EXP, meta.fetch("dir") { "tasks/#{meta.fetch("task")}" }) # change tasks: "dir" = changes/cNN-*
  strict = meta.fetch("strict", 1)
  rec = meta.merge("work" => work)
  if sol.nil?
    rec.merge!("solution" => false, "passed" => 0, "total" => AW.cases(task_dir, "hidden").size, "ok" => false)
  else
    rs = AW.test(sol, task_dir, "hidden", strict)
    # the same program with the checker off: does it pass when nothing stops it before running?
    rs0 = AW.lang_of(sol) == "sake" && strict != 0 ? AW.test(sol, task_dir, "hidden", 0) : rs
    log = File.join(work, "attempts.jsonl")
    attempts = File.exist?(log) ? File.readlines(log).map { JSON.parse(_1) } : []
    rec.merge!("solution" => true, "passed" => rs.count { _1[:ok] }, "total" => rs.size, "ok" => rs.all? { _1[:ok] },
               "ok_without_checker" => rs0.all? { _1[:ok] }, "attempts" => attempts.size,
               "sec_total" => rs.sum { _1[:sec] }.round(3), "sec_max" => rs.map { _1[:sec] }.max.round(3),
               "sec_total_nocheck" => rs0.sum { _1[:sec] }.round(3), # Sake: the same runs at --strict=0 (no checker)
               "diff_lines" => meta["base_ref"] && AW.diff_lines(File.join(AW::EXP, meta["base_ref"]), sol), # change tasks
               "failures" => rs.reject { _1[:ok] }.map { { name: _1[:name], status: _1[:status], err: _1[:err][0, 300] } })
  end
  puts JSON.generate(rec)
end

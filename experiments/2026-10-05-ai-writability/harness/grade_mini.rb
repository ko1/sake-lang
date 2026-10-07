# frozen_string_literal: true

# Grades Mini change tasks (P6): ruby grade_mini.rb WORK_DIR...   One JSON line per work dir.
#   hidden suite: the change's full tests/ on WORK_DIR/code (Sake: must pass --strict=2 -c to run at all;
#     ok_without_checker = the same tests run at --strict=0 regardless of the check);
#   regressions: failing tests among the kept ones (behaviour the change leaves alone);
#   reach: the functions the solution touched (Defs.touched) against those the reference touched for the
#     same codebase: missed = in the reference, not in the solution. Only functions that exist in the
#     original count as missed (a new helper may be named differently).
require_relative "common"
load File.join(__dir__, "validate_mini_change.rb") # Defs

def touched_set(orig, code, ext)
  files = (Dir[File.join(orig, "*.#{ext}")] + Dir[File.join(code, "*.#{ext}")]).map { File.basename(_1) }.uniq
  files.flat_map do |f|
    o, n = File.join(orig, f), File.join(code, f)
    next [] if File.exist?(o) && File.exist?(n) && File.read(o) == File.read(n)
    Defs.touched(File.exist?(o) ? o : nil, File.exist?(n) ? n : nil)
  end.uniq
end

def defs_in(dir, ext) = Dir[File.join(dir, "*.#{ext}")].flat_map { |f| File.readlines(f).filter_map { Defs::DEF.match(_1)&.[](1)&.then { |d| "#{File.basename(f)}:#{d}" } } }.uniq

ARGV.each do |work|
  meta = JSON.parse(File.read(File.join(work, "meta.json")))
  ext, cb = meta.fetch("ext"), meta.fetch("codebase")
  mini = File.join(AW::EXP, "large", "mini")
  change = File.join(mini, "changes", meta.fetch("task"))
  orig, code, ref = File.join(mini, cb), File.join(work, "code"), File.join(change, "ref", cb)
  main = File.join(code, "main.#{ext}")
  check_ok = true
  check_diag = nil
  if ext == "sake"
    out, err, st = AW.run([AW::SAKE, "--strict=2", "-c", main], "", 900)
    check_ok = st == 0
    check_diag = (out + err).lines.grep(/error:/).first(5).join unless check_ok
  end
  cmd = ext == "sake" ? [AW::SAKE, "--strict=0", main] : ["ruby", main]
  tests = Dir[File.join(change, "tests", "*.mini")].sort
  results = tests.to_h do |t|
    got, _e, st = AW.run(cmd, File.read(t), 60)
    [File.basename(t, ".mini"), st == 0 && got == File.read(t.sub(/\.mini\z/, ".out"))]
  end
  kept = File.readlines(File.join(change, "kept.txt"), chomp: true)
  passed0 = results.count { _2 }
  sol = touched_set(orig, code, ext)
  want = touched_set(orig, ref, ext)
  existing = defs_in(orig, ext)
  missed = (want - sol).select { |d| existing.include?(d) || d.end_with?(":<top>", ":<body>") }
  log = File.join(work, "attempts.jsonl")
  atts = File.exist?(log) ? File.readlines(log).map { JSON.parse(_1) } : []
  rec = meta.merge("work" => work, "check_ok" => check_ok, "check_diag" => check_diag,
                   "passed" => check_ok ? passed0 : 0, "total" => tests.size, "ok" => check_ok && passed0 == tests.size,
                   "ok_without_checker" => passed0 == tests.size, "passed_without_checker" => passed0,
                   "regressions" => kept.reject { results[_1] }, "new_failed" => results.reject { |k, v| v || kept.include?(k) }.keys,
                   "diff_lines" => Dir[File.join(orig, "*.#{ext}")].sum { |o| (n = File.join(code, File.basename(o))) && File.exist?(n) ? AW.diff_lines(o, n) : 0 },
                   "touched" => sol.size, "ref_touched" => want.size, "missed" => missed, "extra" => (sol - want),
                   "suite_runs" => atts.count { _1["kind"] == "suite" }, "single_runs" => atts.count { _1["kind"] == "run" },
                   "check_failures" => atts.count { _1["check_ok"] == false },
                   "check_errors" => atts.reject { _1["check_ok"] }.map { _1["diagnostics"].to_s.lines.grep(/error:/).first.to_s.sub(/^.*?error: /, "")[0, 120] })
  puts JSON.generate(rec)
end

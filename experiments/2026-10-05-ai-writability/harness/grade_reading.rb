# frozen_string_literal: true

# Grades the reading tasks (P5): ruby grade_reading.rb WORK_DIR...   One JSON line per work dir.
#   predict: per case, exact match of answers/N.out with the true output, and the share of lines that match
#            (position by position); a missing answer is wrong, never skipped.
#   fix:     hidden tests on solution.<ext> (Sake at --strict=1, and at 0), the lines changed from the bug,
#            and whether the change touches the bug's line.
require_relative "common"

# old-file line numbers covered by diff's hunks (a change or deletion covers its range; an insertion the line before)
def touched(a, b)
  out, _err, _st = AW.run(["diff", a, b], "")
  out.lines.grep(/\A\d/).flat_map do |h|
    from, to = h[/\A(\d+)(?:,(\d+))?/, 1].to_i, (h[/\A\d+,(\d+)/, 1] || h[/\A(\d+)/, 1]).to_i
    h.include?("a") ? [from, from + 1] : (from..to).to_a
  end
end

ARGV.each do |work|
  meta = JSON.parse(File.read(File.join(work, "meta.json")))
  rec = meta.merge("work" => work)
  reading = File.join(AW::EXP, "reading", meta.fetch("task"))
  case meta.fetch("kind")
  when "predict"
    cases = Dir[File.join(reading, "cases", "*.out")].sort.map do |want_f|
      n = File.basename(want_f, ".out")
      want = File.read(want_f)
      ans_f = File.join(work, "answers", "#{n}.out")
      got = File.exist?(ans_f) ? File.read(ans_f) : nil
      wl, gl = want.lines, (got || "").lines
      { case: n, answered: !got.nil?, exact: got == want, lines_ok: wl.each_index.count { wl[_1] == gl[_1] }, lines: wl.size }
    end
    rec.merge!("cases" => cases, "exact" => cases.count { _1[:exact] }, "total" => cases.size)
  when "fix"
    sol = Dir[File.join(work, "solution.{sake,rb}")].first
    task_dir = File.join(AW::EXP, meta.fetch("dir"))
    rs = AW.test(sol, task_dir, "hidden", meta.fetch("strict"))
    rs0 = AW.lang_of(sol) == "sake" ? AW.test(sol, task_dir, "hidden", 0) : rs
    bug = File.join(AW::EXP, meta.fetch("base_ref"))
    rec.merge!("passed" => rs.count { _1[:ok] }, "total" => rs.size, "ok" => rs.all? { _1[:ok] },
               "ok_without_checker" => rs0.all? { _1[:ok] }, "diff_lines" => AW.diff_lines(bug, sol),
               "touched_bug_line" => touched(bug, sol).include?(meta.fetch("bug_line")),
               "failures" => rs.reject { _1[:ok] }.map { { name: _1[:name], status: _1[:status], err: _1[:err][0, 300] } })
  end
  puts JSON.generate(rec)
end

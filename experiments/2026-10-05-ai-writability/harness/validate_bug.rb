# frozen_string_literal: true

# Controls for bug tasks (P5): ruby validate_bug.rb BUG_DIR...   (reading/fNN-*, see brief-bug-tasks.md)
#   one line: bug.<ext> differs from the base ref.<ext> in exactly one line;
#   hidden: the checker does not report it (bug.sake passes --strict=2 -c);
#   matters: it fails 1 .. half of the hidden cases, and exits 0 on all of them (wrong output, no crash);
#   paired: bug.rb and bug.sake give the same stdout and exit status on every public and hidden input.
# Prints bug_line_rb / bug_line_sake (the changed line, for grading), and edit_rb / edit_sake: the changed
# part of the line (common prefix and suffix removed). Equal output on the tests does not prove the two bugs
# are the same (the tests may not separate them), so same_edit=false pairs are reviewed by hand.
# One JSON line each; exit 1 on failure.
require_relative "common"

def changed_lines(a, b)
  out, _err, _st = AW.run(["diff", a, b], "")
  hunks = out.lines.grep(/\A\d/)
  return nil unless hunks.size == 1 && hunks[0] =~ /\A(\d+)c(\d+)\n\z/
  Integer(Regexp.last_match(2))
end

# [removed, added]: the line's changed middle, without the common prefix and suffix
def edit(a, b, line_b)
  out, _err, _st = AW.run(["diff", a, b], "")
  old = out.lines.find { _1.start_with?("< ") }&.delete_prefix("< ")&.chomp or return nil
  new = File.readlines(b)[line_b - 1].chomp
  pre = 0
  pre += 1 while pre < [old.size, new.size].min && old[pre] == new[pre]
  suf = 0
  suf += 1 while suf < [old.size, new.size].min - pre && old[-1 - suf] == new[-1 - suf]
  # widen to whole tokens, so `<=`->`<` and `>=`->`>` do not both read as "removed =" (cut at space , ( ) [ ])
  stop = /[\s,()\[\]]/
  pre -= 1 while pre > 0 && !old[pre - 1].match?(stop)
  suf -= 1 while suf > 0 && !old[-suf].match?(stop)
  [old[pre...(old.size - suf)], new[pre...(new.size - suf)]]
end

bad = false
ARGV.each do |dir|
  base = File.join(AW::EXP, "tasks", File.read(File.join(dir, "base.txt")).strip)
  rec = { bug: File.basename(dir), base: File.basename(base) }
  runs = {}
  %w[rb sake].each do |ext|
    bug = File.join(dir, "bug.#{ext}")
    rec["bug_line_#{ext}"] = changed_lines(File.join(base, "ref.#{ext}"), bug)
    rec["edit_#{ext}"] = rec["bug_line_#{ext}"] && edit(File.join(base, "ref.#{ext}"), bug, rec["bug_line_#{ext}"])
    runs[ext] = AW.test(bug, base, "public", 0) + AW.test(bug, base, "hidden", 0)
  end
  _out, _err, st = AW.run(AW.check_cmd(File.join(dir, "bug.sake"), 2), "")
  rec["sake_check_ok"] = st == 0
  hidden = runs["rb"].last(AW.cases(base, "hidden").size)
  fails = hidden.reject { _1[:ok] }
  rec["hidden_fail"] = fails.size
  rec["hidden_total"] = hidden.size
  rec["fail_exit_nonzero"] = fails.count { _1[:status] != 0 }
  rec["paired"] = runs["rb"].zip(runs["sake"]).all? { |r, s| r[:got] == s[:got] && r[:status] == s[:status] }
  rec["same_edit"] = rec["edit_rb"] == rec["edit_sake"]
  rec["ok"] = !rec["bug_line_rb"].nil? && !rec["bug_line_sake"].nil? && rec["sake_check_ok"] && fails.size >= 1 &&
              fails.size * 2 <= hidden.size && rec["fail_exit_nonzero"].zero? && rec["paired"]
  bad ||= !rec["ok"]
  puts JSON.generate(rec)
end
exit(bad ? 1 : 0)

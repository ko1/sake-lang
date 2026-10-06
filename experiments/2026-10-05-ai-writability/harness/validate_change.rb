# frozen_string_literal: true

# Controls for change tasks: ruby validate_change.rb CHANGE_DIR...   (changes/cNN-*, see brief-change-tasks.md)
#   positive: the new ref.sake (at --strict=2) and ref.rb pass every public and hidden case;
#   the change matters: each base reference fails at least 2 hidden cases;
#   kept behaviour: at least 4 hidden cases pass with both base references;
#   negative: mutants of the new references fail some hidden case.
# Also prints diff_rb / diff_sake: lines changed from the base reference (diff's < and > lines).
# One JSON line per change; exit 1 when any check fails.
require_relative "common"

bad = false
ARGV.each do |dir|
  base = File.join(AW::EXP, "tasks", File.read(File.join(dir, "base.txt")).strip)
  rec = { change: File.basename(dir), base: File.basename(base) }
  kept = nil
  %w[sake rb].each do |ext|
    ref = File.join(dir, "ref.#{ext}")
    old = File.join(base, "ref.#{ext}")
    strict = ext == "sake" ? 2 : 0
    res = AW.test(ref, dir, "public", strict) + AW.test(ref, dir, "hidden", strict)
    rec["#{ext}_ref_ok"] = res.all? { _1[:ok] }
    rec["#{ext}_ref_fail"] = res.reject { _1[:ok] }.map { |r| [r[:name], r[:status], r[:err][0, 200]] }
    olds = AW.test(old, dir, "hidden", strict)
    rec["#{ext}_base_fails"] = olds.count { !_1[:ok] }
    pass = olds.select { _1[:ok] }.map { _1[:name] }
    kept = kept ? kept & pass : pass
    ms = AW.mutants(File.read(ref)).sample(12, random: Random.new(1))
    tmp = File.join(dir, ".mutant.#{ext}")
    rec["#{ext}_mutants"] = ms.size
    rec["#{ext}_killed"] = ms.count do |m|
      File.write(tmp, m)
      AW.test(tmp, dir, "hidden", 0).any? { !_1[:ok] }
    end
    File.delete(tmp) if File.exist?(tmp)
    rec["diff_#{ext}"] = AW.diff_lines(old, ref)
  end
  rec["kept_cases"] = kept.size
  rec["ok"] = rec["sake_ref_ok"] && rec["rb_ref_ok"] && rec["sake_base_fails"] >= 2 && rec["rb_base_fails"] >= 2 &&
              kept.size >= 4 && rec["sake_killed"] > 0 && rec["rb_killed"] > 0
  bad ||= !rec["ok"]
  puts JSON.generate(rec)
end
exit(bad ? 1 : 0)

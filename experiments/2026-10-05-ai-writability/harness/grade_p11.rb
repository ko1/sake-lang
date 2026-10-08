# frozen_string_literal: true

# P11: grades a change run, or the unchanged engine (the baseline).
#   ruby harness/grade_p11.rb RUN              grades runs/RUN/code (copied to runs/RUN/final/code first)
#   ruby harness/grade_p11.rb --baseline SRC [CHANGE...]   grades runs/SRC/stage-6/code (all changes in one run)
# Suites: public = large/sql/tests/1..6 + the change's public tests (as 7); hidden = tasks/sql-hidden/1..6
# + the change's hidden tests (as 7), run together in one run_tests.rb call (one check). Records each failed
# test's name, so that
#   - regressions = failed stage 1-6 tests that the unchanged engine passed (baseline),
#   - per site = passed/total of the change's hidden tests by the site in their file name (NNN-<site>-...).
# Appends to runs/grade-p11.jsonl (runs) or runs/baseline-p11.jsonl. A count it cannot read fails the script.
require "fileutils"
require "tmpdir"
require_relative "common"

SQL = File.join(AW::EXP, "large", "sql")

# One run of run_tests.rb over a tree of numbered directories (one check for the whole grade): PARTS maps a
# directory number to [source dir, prefix]; returns [all names, failed names, seconds, note] with each test
# named "<prefix>/<file>" (prefix "pub/7", "hid/3", ...).
def run_tree(main, flags, parts)
  Dir.mktmpdir("p11-grade") do |tmp|
    parts.each { |n, (dir, _)| File.symlink(dir, File.join(tmp, n.to_s)) }
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    out, err, _st = Open3.capture3({ "SQL_TESTS" => tmp, "SQL_CHECK_TIMEOUT" => "3600" }, "ruby", File.join(SQL, "run_tests.rb"), main, *flags)
    secs = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
    text = out + err
    name = ->(n, file) { "#{parts.fetch(Integer(n))[1]}/#{file}" }
    all = parts.flat_map { |n, (dir, _)| Dir.glob(File.join(dir, "*.sql")).map { name.(n, File.basename(_1, ".sql")) } }.sort
    raise CheckTimeout, text.lines.first if text.start_with?("CHECK TIMED OUT")
    return [all, all, secs, "check failed"] if text.start_with?("CHECK FAILED")
    m = text.match(/^(\d+) passed, (\d+) failed \((\d+) tests/) or abort "no summary line:\n#{text.lines.last(10).join}"
    failed = text.scan(%r{^(?:FAIL|MISSING) (\d+)/([^:]+):}).map { |n, f| name.(n, f) }.sort
    $timeouts.concat(text.scan(%r{^FAIL (\d+)/([^:]+): timed out}).map { |n, f| name.(n, f) })
    abort "runner ran #{m[3]} tests, expected #{all.size}" unless Integer(m[3]) == all.size
    abort "runner failed #{m[2]}, parsed #{failed.size}" unless Integer(m[2]) == failed.size
    [all, failed, secs, nil]
  end
end

# The check did not finish (load): no grade is recorded; the run's final/ is removed so it can be graded again.
class CheckTimeout < StandardError; end

OLD_PUB = File.join(SQL, "tests")
OLD_HID = File.join(AW::EXP, "tasks", "sql-hidden")
def change_pub(change) = File.join(SQL, "changes", change, "tests", "7")
def change_hid(change) = File.join(AW::EXP, "tasks", "sql-change-hidden", change, "7")

# Splits run_tree's names into the public and hidden lists of one change, named "N/file" (7 = the change).
def split_for(names, change)
  pick = ->(kind) do
    names.filter_map do |x|
      k, n, f = x.split("/", 3)
      next unless k == kind
      next "#{n}/#{f}" if n.match?(/\A[1-6]\z/)
      "7/#{f}" if n == change
    end.sort
  end
  [pick.("pub"), pick.("hid")]
end

def old_parts
  (1..6).to_h { |n| [n, [File.join(OLD_PUB, n.to_s), "pub/#{n}"]] }.merge((1..6).to_h { |n| [10 + n, [File.join(OLD_HID, n.to_s), "hid/#{n}"]] })
end

def sites_of(change)
  text = File.read(File.join(SQL, "changes", change, "change.md"))
  sec = text.split(/^## Where it applies\s*$/)[1] or abort "no 'Where it applies' in #{change}"
  sec.scan(/^- ([a-z0-9_-]+)( \(public\))?:/).map { |id, pub| [id, !pub.nil?] }.to_h
end

def site_of(test, sites)
  base = test.delete_prefix("7/").sub(/\A\d+-/, "")
  return "mixed" if base.start_with?("mixed-")
  sites.keys.sort_by { -_1.size }.find { base.start_with?("#{_1}-") } or abort "test #{test}: no site in its name"
end

$timeouts = []

# A test that timed out may be the machine's load, not the program: they are recorded apart (timeouts:).
def grade(main, flags, change)
  parts = old_parts.merge(7 => [change_pub(change), "pub/#{change}"], 17 => [change_hid(change), "hid/#{change}"])
  all, failed, secs, note = run_tree(main, flags, parts)
  pa, ha = split_for(all, change)
  pf, hf = split_for(failed, change)
  { public_total: pa.size, public_failed: pf, hidden_total: ha.size, hidden_failed: hf,
    suite_secs: secs.round(1), timeouts: $timeouts.dup, note: note.to_s }
end

if ARGV[0] == "--baseline"
  # --baseline SRC [CHANGE...]: every change (default: those with a change.md and no baseline yet) in one run.
  _, src, *changes = ARGV
  base_file = File.join(AW::EXP, "runs", "baseline-p11.jsonl")
  done = File.exist?(base_file) ? File.readlines(base_file).map { r = JSON.parse(_1); [r["src"], r["change"]] } : []
  changes = Dir.glob(File.join(SQL, "changes", "*", "change.md")).map { File.basename(File.dirname(_1)) }.sort if changes.empty?
  changes -= done.select { _1[0] == src }.map(&:last)
  exit if changes.empty?
  meta = JSON.parse(File.read(File.join(AW::EXP, "runs", src, "meta.json")))
  entry = meta["entry"] || "main.#{meta["ext"]}"
  main = File.join(AW::EXP, "runs", src, "stage-6", "code", entry)
  parts = old_parts
  changes.each_with_index { |c, i| parts[20 + i] = [change_pub(c), "pub/#{c}"]; parts[40 + i] = [change_hid(c), "hid/#{c}"] }
  all, failed, secs, note = run_tree(main, meta["flag"].to_s.split, parts)
  changes.each do |c|
    pa, ha = split_for(all, c)
    pf, hf = split_for(failed, c)
    row = { src:, change: c, lang: meta["lang"], public_total: pa.size, public_failed: pf, hidden_total: ha.size, hidden_failed: hf,
            suite_secs: secs.round(1), timeouts: $timeouts.select { _1.include?("/#{c}/") || _1.match?(%r{\A\w+/[1-6]/}) }, note: note.to_s }
    File.open(base_file, "a") { _1.puts(JSON.generate(row)) }
    puts "#{src} #{c}: public failed #{pf.size}/#{pa.size} hidden failed #{hf.size}/#{ha.size} timeouts #{row[:timeouts].size} #{note}"
  end
  exit
end

run = ARGV[0] or abort "usage: grade_p11.rb RUN | --baseline SRC CHANGE"
work = File.join(AW::EXP, "runs", run)
meta = JSON.parse(File.read(File.join(work, "meta.json")))
change = meta["change"]
final = File.join(work, "final")
begin
  Dir.mkdir(final) # atomic: a second grader of the same run stops here
rescue Errno::EEXIST
  abort "#{final} exists"
end
FileUtils.cp_r(File.join(work, "code"), File.join(final, "code"))
main = File.join(final, "code", meta["entry"])

base = File.readlines(File.join(AW::EXP, "runs", "baseline-p11.jsonl")).map { JSON.parse(_1) }
             .reverse.find { _1["src"] == meta["src"] && _1["change"] == change } or abort "no baseline for #{meta["src"]} #{change}"
begin
  g = grade(main, meta["flag"].to_s.split, change)
rescue CheckTimeout => e
  FileUtils.rm_rf(final)
  abort "#{run}: #{e.message.strip} (not graded; final/ removed)"
end
sites = sites_of(change)
hid7 = Dir.glob(File.join(AW::EXP, "tasks", "sql-change-hidden", change, "7", "*.sql")).map { "7/#{File.basename(_1, ".sql")}" }.sort
per_site = hid7.group_by { site_of(_1, sites) }.transform_values do |ts|
  { "pass" => ts.count { !g[:hidden_failed].include?(_1) }, "total" => ts.size, "baseline_pass" => ts.count { !base["hidden_failed"].include?(_1) } }
end
old = ->(list) { list.reject { _1.start_with?("7/") } }
src_code = File.join(AW::EXP, "runs", meta["src"], "stage-6", "code")
diff, _ = Open3.capture2("diff", "-ruN", src_code, File.join(final, "code"))
row = {
  run:, mode: meta["mode"], lang: meta["lang"], series: meta["series"], change:,
  public7: "#{g[:public_total] - g[:public_failed].size - old.(Dir.glob(File.join(SQL, "tests", "*", "*.sql"))).size}",
  public_pass: g[:public_total] - g[:public_failed].size, public_total: g[:public_total],
  hidden7_pass: hid7.count { !g[:hidden_failed].include?(_1) }, hidden7_total: hid7.size,
  regressions_public: old.(g[:public_failed]) - old.(base["public_failed"]),
  regressions_hidden: old.(g[:hidden_failed]) - old.(base["hidden_failed"]),
  per_site:, sites_public: sites.select { _2 }.keys,
  diff_added: diff.lines.count { _1.start_with?("+") && !_1.start_with?("+++") },
  diff_removed: diff.lines.count { _1.start_with?("-") && !_1.start_with?("---") },
  files_changed: diff.lines.count { _1.start_with?("diff ") },
  hidden_failed: g[:hidden_failed], public_failed: g[:public_failed], suite_secs: g[:suite_secs], timeouts: g[:timeouts], note: g[:note],
}
row.delete(:public7)
File.open(File.join(AW::EXP, "runs", "grade-p11.jsonl"), "a") { _1.puts(JSON.generate(row)) }
puts "#{run}: change hidden #{row[:hidden7_pass]}/#{row[:hidden7_total]} public #{row[:public_pass]}/#{row[:public_total]} " \
     "regressions #{row[:regressions_hidden].size}+#{row[:regressions_public].size} diff +#{row[:diff_added]}/-#{row[:diff_removed]} timeouts #{row[:timeouts].size} #{row[:note]}"

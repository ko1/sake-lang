# frozen_string_literal: true

# The solver's only tool in the no-run SQL change tasks (P11 mode n): ruby check_sql.rb WORK_DIR
# Runs the language's check on code/ (large/sql/run_tests.rb --check-only) and nothing else. Logs each call
# to WORK_DIR/attempts.jsonl with a copy of the changed files in WORK_DIR/attempt-NN/. At most
# meta.max_checks calls.
require "fileutils"
require_relative "common"

work = File.expand_path(ARGV.shift || abort("usage: check_sql.rb WORK_DIR"))
meta = JSON.parse(File.read(File.join(work, "meta.json")))
code = File.join(work, "code")
orig = File.join(AW::EXP, "runs", meta.fetch("src"), "stage-6", "code")
log = File.join(work, "attempts.jsonl")
past = File.exist?(log) ? File.readlines(log).map { JSON.parse(_1) } : []
limit = meta.fetch("max_checks")
if past.size >= limit
  puts "no checks left (#{limit} used); stop here: your code as it is now is graded"
  exit 1
end
n = past.size + 1
changed = Dir[File.join(code, "**", "*")].select { File.file?(_1) }.reject do |f|
  o = File.join(orig, f.delete_prefix(code + "/"))
  File.exist?(o) && File.read(o) == File.read(f)
end
changed.each do |f|
  dst = File.join(work, format("attempt-%02d", n), f.delete_prefix(code + "/"))
  FileUtils.mkdir_p(File.dirname(dst))
  FileUtils.cp(f, dst)
end

runner = File.join(AW::EXP, "large", "sql", "run_tests.rb")
t0 = Time.now.to_f
out, st = Open3.capture2e("ruby", runner, File.join(code, meta.fetch("entry")), *meta.fetch("flag").split, "--check-only")
ok = st.success?
puts "== check #{n} of #{limit}: #{ok ? "ok" : "FAILED"}"
puts out.lines.reject { _1.start_with?("CHECK OK") }.first(40).join
File.open(log, "a") do |f|
  f.puts JSON.generate({ attempt: n, kind: "check", time: t0, secs: (Time.now.to_f - t0).round(1), check_ok: ok,
                         changed_files: changed.map { _1.delete_prefix(code + "/") }, diagnostics: out[0, 20_000] })
end

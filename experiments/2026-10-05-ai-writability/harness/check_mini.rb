# frozen_string_literal: true

# The solver's only tool in the no-test Mini change tasks (P8): ruby check_mini.rb WORK_DIR
# Checks code/ without running anything: Sake `bin/sake --strict=2 -c code/main.sake`, Ruby `ruby -wc` on
# every code/*.rb. Logs each call to WORK_DIR/attempts.jsonl (kind "check") with a copy of the changed files
# in WORK_DIR/attempt-NN/. At most meta.max_attempts calls.
require "fileutils"
require_relative "common"

work = File.expand_path(ARGV.shift || abort("usage: check_mini.rb WORK_DIR"))
meta = JSON.parse(File.read(File.join(work, "meta.json")))
ext = meta.fetch("ext")
code = File.join(work, "code")
orig = File.join(AW::EXP, "large", "mini", meta.fetch("codebase"))
log = File.join(work, "attempts.jsonl")
past = File.exist?(log) ? File.readlines(log).map { JSON.parse(_1) } : []
limit = meta.fetch("max_attempts")
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

rec = { attempt: n, kind: "check", time: Time.now.to_f, changed_files: changed.map { _1.delete_prefix(code + "/") } }
if ext == "sake"
  out, err, st = AW.run([AW::SAKE, "--strict=2", "-c", File.join(code, "main.sake")], "", 900)
  diag = (out + err).lines.reject { _1.end_with?(": OK\n") }.join
  rec[:check_ok] = st == 0
  puts "== check (bin/sake --strict=2 -c): #{st == 0 ? "ok" : st == :timeout ? "TIMED OUT (900 s)" : "FAILED"}"
else
  diag = +""
  ok = true
  Dir[File.join(code, "*.rb")].sort.each do |f|
    out, err, st = AW.run(["ruby", "-wc", f], "")
    ok &&= st == 0
    diag << (out + err).lines.reject { _1 == "Syntax OK\n" }.join
  end
  rec[:check_ok] = ok
  puts "== check (ruby -wc on every file): #{ok ? "ok" : "FAILED"}"
end
puts diag.lines.first(40).join unless diag.empty?
rec[:diagnostics] = diag[0, 20_000]
puts "== check #{n} of #{limit}"
File.open(log, "a") { _1.puts JSON.generate(rec) }

# frozen_string_literal: true

# The solver's only way to run code in a Mini change task (P6):
#   ruby try_mini.rb WORK_DIR [NAME_SUBSTRING...]   check (Sake: --strict=2 -c) and run the regression tests
#                                                   in WORK_DIR/tests (all, or those whose name matches)
#   ruby try_mini.rb WORK_DIR --run FILE.mini       check, then run one Mini program and show its output
# Each call is logged to WORK_DIR/attempts.jsonl, with a copy of the files that differ from the original
# codebase in WORK_DIR/attempt-NN/. At most meta.max_attempts suite runs and 3x as many single runs.
require "fileutils"
require_relative "common"

work = File.expand_path(ARGV.shift || abort("usage: try_mini.rb WORK_DIR [NAME...] | WORK_DIR --run FILE.mini"))
meta = JSON.parse(File.read(File.join(work, "meta.json")))
ext = meta.fetch("ext")
code = File.join(work, "code")
main = File.join(code, "main.#{ext}")
orig = File.join(AW::EXP, "large", "mini", meta.fetch("codebase"))
log = File.join(work, "attempts.jsonl")
past = File.exist?(log) ? File.readlines(log).map { JSON.parse(_1) } : []
single = ARGV[0] == "--run"
kind = single ? "run" : "suite"
limit = single ? meta.fetch("max_attempts") * 3 : meta.fetch("max_attempts")
used = past.count { _1["kind"] == kind }
if used >= limit
  puts "no #{kind} attempts left (#{limit} used); stop here: your code as it is now is graded"
  exit 1
end
n = past.size + 1

snap = File.join(work, format("attempt-%02d", n))
changed = Dir[File.join(code, "**", "*")].select { File.file?(_1) }.reject do |f|
  o = File.join(orig, f.delete_prefix(code + "/"))
  File.exist?(o) && File.read(o) == File.read(f)
end
changed.each do |f|
  dst = File.join(snap, f.delete_prefix(code + "/"))
  FileUtils.mkdir_p(File.dirname(dst))
  FileUtils.cp(f, dst)
end

rec = { attempt: n, kind:, time: Time.now.to_f, changed_files: changed.map { _1.delete_prefix(code + "/") } }
if ext == "sake"
  out, err, st = AW.run([AW::SAKE, "--strict=2", "-c", main], "", 900)
  diag = (out + err).lines.reject { _1.end_with?(": OK\n") }.join
  rec[:check_ok] = st == 0
  rec[:diagnostics] = diag[0, 20_000]
  puts "== check (bin/sake --strict=2 -c): #{st == 0 ? "ok" : st == :timeout ? "TIMED OUT (900 s)" : "FAILED"}"
  puts diag.lines.first(40).join unless diag.empty?
  run_cmd = [AW::SAKE, "--strict=0", main]
else
  out, err, st = AW.run(["ruby", "-wc", main], "")
  rec[:check_ok] = st == 0
  puts "== check (ruby -wc main.rb): #{st == 0 ? "ok" : "FAILED"}"
  puts (out + err).lines.reject { _1 == "Syntax OK\n" }.first(20).join
  run_cmd = ["ruby", main]
end

if rec[:check_ok]
  if single
    file = File.expand_path(ARGV[1] || abort("--run needs a FILE.mini"))
    got, e, st = AW.run(run_cmd, File.read(file), 60)
    puts "== output of #{File.basename(file)}#{st == 0 ? "" : " (exit #{st})"}:"
    puts got
    puts "-- stderr:\n#{e.lines.first(10).join}" unless e.empty?
    rec[:file] = File.basename(file)
  else
    tests = Dir[File.join(work, "tests", "*.mini")].sort
    tests = tests.select { |t| ARGV.any? { File.basename(t).include?(_1) } } unless ARGV.empty?
    fails = tests.filter_map do |t|
      got, e, st = AW.run(run_cmd, File.read(t), 60)
      want = File.read(t.sub(/\.mini\z/, ".out"))
      next if st == 0 && got == want
      i = 0
      i += 1 while i < want.lines.size && want.lines[i] == got.lines[i]
      { name: File.basename(t, ".mini"), status: st, line: i + 1, want: want.lines[i].to_s.chomp, got: got.lines[i].to_s.chomp, err: e[0, 300] }
    end
    puts "== regression tests: #{tests.size - fails.size} passed, #{fails.size} failed (of #{tests.size})"
    fails.first(10).each do |f|
      puts "FAIL #{f[:name]} (line #{f[:line]}#{f[:status] == 0 ? "" : ", exit #{f[:status]}"})\n  expected: #{f[:want].inspect}\n  actual:   #{f[:got].inspect}"
      puts "  stderr: #{f[:err].lines.first.to_s.chomp}" unless f[:err].empty?
    end
    rec.merge!(tests: tests.size, failed: fails.map { _1[:name] })
  end
end
puts "== #{kind} attempt #{used + 1} of #{limit}"
File.open(log, "a") { _1.puts JSON.generate(rec) }

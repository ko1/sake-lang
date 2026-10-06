# frozen_string_literal: true

# The solver's only way to run code: ruby try.rb FILE   (FILE: solution.sake or solution.rb in a task's
# work directory). Saves the attempt, checks it, runs it on the public examples, prints the result,
# and appends a record to attempts.jsonl next to FILE. Env: AW_STRICT (Sake's level, default 1).
require_relative "common"

file = File.expand_path(ARGV.fetch(0))
work = File.dirname(file)
meta = JSON.parse(File.read(File.join(work, "meta.json")))
task_dir = File.join(AW::EXP, "tasks", meta.fetch("task"))
strict = meta.fetch("strict", 1)
log = File.join(work, "attempts.jsonl")
n = File.exist?(log) ? File.readlines(log).size + 1 : 1
if meta["max_attempts"] && n > meta["max_attempts"]
  puts "no attempts left (#{meta["max_attempts"]} used); stop here: your last file is graded as it is"
  exit 1
end
src = File.read(file)
File.write(File.join(work, format("attempt-%02d%s", n, File.extname(file))), src)

check_out, check_err, check_st = AW.run(AW.check_cmd(file, strict), "")
diag = (check_out + check_err).lines.reject { _1.end_with?(": OK\n") || _1 == "Syntax OK\n" }.join
results = check_st == 0 ? AW.test(file, task_dir, "public", strict) : []
puts "== check (#{AW.lang_of(file) == "sake" ? "bin/sake --strict=#{strict} -c" : "ruby -wc"}): #{check_st == 0 ? "ok" : "FAILED"}"
puts diag unless diag.empty?
results.each do |r|
  puts "== example #{r[:name]}: #{r[:ok] ? "pass" : "FAIL (exit #{r[:status]})"}"
  next if r[:ok]
  puts "-- expected:\n#{r[:want]}-- got:\n#{r[:got]}"
  puts "-- stderr:\n#{r[:err]}" unless r[:err].empty?
end
puts "== attempt #{n}#{meta["max_attempts"] ? " of #{meta["max_attempts"]}" : ""}"
File.open(log, "a") do |f|
  f.puts JSON.generate(attempt: n, time: Time.now.to_f, bytes: src.bytesize, check_ok: check_st == 0, diagnostics: diag,
                       examples: results.map { { name: _1[:name], ok: _1[:ok], status: _1[:status], stderr: _1[:err][0, 2000] } })
end

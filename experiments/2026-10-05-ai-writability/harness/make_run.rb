# frozen_string_literal: true

# Makes a run's work directories: ruby make_run.rb RUN_ID LANG MODE STRICT TASK...
#   LANG: sake | ruby; MODE: oneshot (no running) | agentic (try.rb, at most 8 attempts)
# runs/RUN_ID/<task>/ gets spec.md, public/, meta.json; the solver writes solution.<ext> there.
require "fileutils"
require "json"

run_id, lang, mode, strict, *tasks = ARGV
exp = File.expand_path("..", __dir__)
tasks.each do |t|
  work = File.join(exp, "runs", run_id, t)
  abort "#{work} exists" if File.exist?(work)
  FileUtils.mkdir_p(work)
  FileUtils.cp(File.join(exp, "tasks", t, "spec.md"), work)
  FileUtils.cp_r(File.join(exp, "tasks", t, "public"), work)
  meta = { task: t, lang:, mode:, strict: Integer(strict), run: run_id, max_attempts: mode == "agentic" ? 8 : 0 }
  File.write(File.join(work, "meta.json"), JSON.pretty_generate(meta))
end

# frozen_string_literal: true

# Makes a run's work directories for change tasks: ruby make_change_run.rb RUN_ID LANG MODE STRICT CHANGE...
#   CHANGE: a directory name under changes/ (cNN-*). runs/RUN_ID/<change>/ gets the base task's spec.md,
#   the change's change.md and public/, and the base reference as solution.<ext> (the program to modify).
require "fileutils"
require "json"

run_id, lang, mode, strict, *changes = ARGV
exp = File.expand_path("..", __dir__)
ext = { "sake" => "sake", "ruby" => "rb" }.fetch(lang)
changes.each do |c|
  dir = File.join(exp, "changes", c)
  base = File.read(File.join(dir, "base.txt")).strip
  work = File.join(exp, "runs", run_id, c)
  abort "#{work} exists" if File.exist?(work)
  FileUtils.mkdir_p(work)
  FileUtils.cp(File.join(exp, "tasks", base, "spec.md"), work)
  FileUtils.cp(File.join(dir, "change.md"), work)
  FileUtils.cp_r(File.join(dir, "public"), work)
  FileUtils.cp(File.join(exp, "tasks", base, "ref.#{ext}"), File.join(work, "solution.#{ext}"))
  meta = { task: c, dir: "changes/#{c}", base_ref: "tasks/#{base}/ref.#{ext}", lang:, mode:, strict: Integer(strict), run: run_id,
           max_attempts: mode == "agentic" ? 8 : 0 }
  File.write(File.join(work, "meta.json"), JSON.pretty_generate(meta))
end

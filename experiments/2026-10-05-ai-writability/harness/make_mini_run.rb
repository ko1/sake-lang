# frozen_string_literal: true

# Work directories for the Mini change tasks (P6): ruby make_mini_run.rb RUN_ID CODEBASE CHANGE...
#   CODEBASE: ruby | sake (the port) | sake-scratch. CHANGE: a directory name under large/mini/changes/.
# runs/RUN_ID/<change>/ gets code/ (a copy of the codebase), SPEC.md, change.md, and tests/ = the
# regression suite: the change's tests whose expected output every original codebase already produces
# (behaviour the change must keep). The hidden suite is the change's full tests/ (grade_mini.rb).
require "fileutils"
require_relative "common"

run_id, codebase, *changes = ARGV
mini = File.join(AW::EXP, "large", "mini")
ext = codebase == "ruby" ? "rb" : "sake"
abort "CODEBASE: ruby | sake | sake-scratch" unless %w[ruby sake sake-scratch].include?(codebase)
changes.each do |c|
  dir = File.join(mini, "changes", c)
  kept_f = File.join(dir, "kept.txt")
  abort "#{kept_f} missing: run validate_mini_change.rb --write-kept first" unless File.exist?(kept_f)
  work = File.join(AW::EXP, "runs", run_id, c)
  abort "#{work} exists" if File.exist?(work)
  FileUtils.mkdir_p(File.join(work, "tests"))
  FileUtils.cp_r(File.join(mini, codebase), File.join(work, "code"))
  FileUtils.cp(File.join(mini, "SPEC.md"), work)
  FileUtils.cp(File.join(dir, "change.md"), work)
  File.readlines(kept_f, chomp: true).each do |name|
    %w[mini out].each { FileUtils.cp(File.join(dir, "tests", "#{name}.#{_1}"), File.join(work, "tests")) }
  end
  meta = { task: c, codebase:, lang: ext == "rb" ? "ruby" : "sake", run: run_id, ext:, max_attempts: 10 }
  File.write(File.join(work, "meta.json"), JSON.pretty_generate(meta))
end

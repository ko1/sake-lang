# frozen_string_literal: true

# Work directories for the reading tasks (P5): ruby make_reading_run.rb RUN_ID LANG KIND TASK...
#   KIND predict, TASK reading/pNN-*: program.<ext> (the base reference) and cases/N.in; the reader writes answers/N.out.
#   KIND fix, TASK reading/fNN-*: solution.<ext> (the bug), spec.md, and example/ = the first hidden case the bug
#   fails (input.txt, expected.txt, actual.txt). The reader edits solution.<ext>; grade_reading.rb grades both.
require "fileutils"
require_relative "common"

run_id, lang, kind, *tasks = ARGV
ext = { "sake" => "sake", "ruby" => "rb" }.fetch(lang)
tasks.each do |t|
  dir = File.join(AW::EXP, "reading", t)
  base = File.read(File.join(dir, "base.txt")).strip
  base_dir = File.join(AW::EXP, "tasks", base)
  work = File.join(AW::EXP, "runs", run_id, t)
  abort "#{work} exists" if File.exist?(work)
  FileUtils.mkdir_p(work)
  meta = { task: t, kind:, lang:, run: run_id, base: }
  case kind
  when "predict"
    FileUtils.cp(File.join(base_dir, "ref.#{ext}"), File.join(work, "program.#{ext}"))
    FileUtils.mkdir_p(File.join(work, "cases"))
    FileUtils.mkdir_p(File.join(work, "answers"))
    Dir[File.join(dir, "cases", "*.in")].each { FileUtils.cp(_1, File.join(work, "cases")) }
  when "fix"
    bug = File.join(dir, "bug.#{ext}")
    FileUtils.cp(bug, File.join(work, "solution.#{ext}"))
    FileUtils.cp(File.join(base_dir, "spec.md"), work)
    fail = AW.test(bug, base_dir, "hidden", 0).find { !_1[:ok] } or abort "#{t}: the bug fails no hidden case"
    ex = File.join(work, "example")
    FileUtils.mkdir_p(ex)
    File.write(File.join(ex, "input.txt"), File.read(File.join(base_dir, "hidden", "#{fail[:name]}.in")))
    File.write(File.join(ex, "expected.txt"), fail[:want])
    File.write(File.join(ex, "actual.txt"), fail[:got])
    lines = JSON.parse(File.read(File.join(dir, "bug_lines.json")))
    meta.merge!(dir: "tasks/#{base}", base_ref: "reading/#{t}/bug.#{ext}", bug_line: lines.fetch(ext), example_case: fail[:name], strict: 1)
  else abort "KIND: predict | fix"
  end
  File.write(File.join(work, "meta.json"), JSON.pretty_generate(meta))
end

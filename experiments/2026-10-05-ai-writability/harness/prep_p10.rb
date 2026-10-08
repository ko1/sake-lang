# frozen_string_literal: true

# P10 (SQL engine in stages): prepares stage STAGE of run RUN and writes its prompt.
#   ruby harness/prep_p10.rb RUN ruby|sake STAGE
# runs/RUN/ holds SPEC.md (spec files 1..STAGE), tests/1..STAGE (public), run_tests.rb, code/ (the
# program, kept across stages) and stage-N/code (a copy of code/ taken by snapshot_p10.rb after stage N).
# Stage 1 starts with an empty code/; stage N > 1 needs stage-(N-1)/ to exist (the previous stage done).
require "fileutils"
require_relative "common"

run, lang, stage_s = ARGV
abort "usage: prep_p10.rb RUN ruby|sake STAGE" unless run && %w[ruby sake].include?(lang) && stage_s
stage = Integer(stage_s)
sql = File.join(AW::EXP, "large", "sql")
work = File.join(AW::EXP, "runs", run)
ext = lang == "ruby" ? "rb" : "sake"

if stage == 1
  abort "#{work} exists" if File.exist?(work)
  FileUtils.mkdir_p(File.join(work, "code"))
else
  prev = File.join(work, "stage-#{stage - 1}")
  abort "#{prev} missing: snapshot stage #{stage - 1} first" unless File.directory?(prev)
  abort "#{work}/stage-#{stage} exists" if File.exist?(File.join(work, "stage-#{stage}"))
end

specs = Dir.glob(File.join(sql, "spec", "*.md")).sort.select { |f| File.basename(f).to_i.between?(1, stage) }
abort "spec files missing" unless specs.length == stage
File.write(File.join(work, "SPEC.md"),
           "# A small SQL engine: specification, stages 1..#{stage}\n\n" + specs.map { File.read(_1) }.join("\n"))
FileUtils.rm_rf(File.join(work, "tests"))
(1..stage).each do |n|
  src = File.join(sql, "tests", n.to_s)
  abort "#{src} has no tests" if Dir.glob(File.join(src, "*.sql")).empty?
  FileUtils.mkdir_p(File.join(work, "tests"))
  FileUtils.cp_r(src, File.join(work, "tests", n.to_s))
end
FileUtils.cp(File.join(sql, "run_tests.rb"), work)
File.write(File.join(work, "meta.json"), JSON.pretty_generate({ run:, lang:, ext:, stage: }))

name = lang == "ruby" ? "Ruby (4.0; the standard library is allowed)" : "Sake"
new_note = stage == 1 ? "" : "Stage #{stage} (the last part, \"Stage #{stage}: ...\") is new in this task; stages 1..#{stage - 1} are what the program already does."
check_note = lang == "ruby" ? "" : "For Sake it first checks the program with `/home/ko1/app/sake/bin/sake --strict=2 -c` (this can take minutes on a large program; a program it rejects does not run), then runs each test at `--strict=0`."
code_note = stage == 1 ? "empty: the program goes here, entry `main.#{ext}`." : "the program so far, entry `main.#{ext}`, written by the previous stages; it passes every test of stages 1..#{stage - 1}."
job_note = stage == 1 ? "Write the program in `code/`, entry `main.#{ext}`: it reads a SQL script from standard input and runs it, as SPEC.md says." : "Extend the program in `code/` to stage #{stage}, keeping stages 1..#{stage - 1} working. Restructure what the new stage calls for."
lang_note = lang == "ruby" ? "" : "**Sake** (in `/home/ko1/app/sake`): Ruby syntax where every operation is written with its type (`String.upcase(s)`, not `s.upcase`). Learn it from `docs/tutorial.md` (start here), `docs/spec.md` and `docs/builtins.md`; these are the only documents you may read. Run a program with `/home/ko1/app/sake/bin/sake --strict=2 main.sake`."
brief = File.read(File.join(AW::EXP, "brief-sql-build.md"))
prompt = brief.gsub("WORK_DIR") { work }.gsub("**LANG**") { "**#{name}**" }.gsub("STAGE") { stage.to_s }
              .gsub("EXT") { ext }.gsub("NEW_NOTE") { new_note }.gsub("CHECK_NOTE") { check_note }
              .gsub("CODE_NOTE") { code_note }.gsub("JOB_NOTE") { job_note }.gsub("LANG_NOTE") { lang_note }
prompt = prompt.gsub(/\n{3,}/, "\n\n").rstrip + "\n"
path = File.join(AW::EXP, "prompts", "#{run}-s#{stage}.md")
File.write(path, prompt)
puts path

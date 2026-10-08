# frozen_string_literal: true

# P10 (SQL engine in stages): prepares stage STAGE of run RUN and writes its prompt.
#   ruby harness/prep_p10.rb RUN LANG STAGE     (LANG: ruby sake java haskell scheme steep)
# runs/RUN/ holds SPEC.md (spec files 1..STAGE), tests/1..STAGE (public), run_tests.rb, code/ (the
# program, kept across stages) and stage-N/code (a copy of code/ taken by snapshot_p10.rb after stage N).
# Stage 1 starts with an empty code/; stage N > 1 needs stage-(N-1)/ to exist (the previous stage done).
require "fileutils"
require_relative "common"

# entry file, source extensions counted as the program's lines, run_tests.rb's extra flag, and the
# language's name and note in the brief.
LANGS = {
  "ruby" => { entry: "main.rb", exts: %w[rb], flag: "", name: "Ruby (4.0; the standard library is allowed)", note: "" },
  "sake" => { entry: "main.sake", exts: %w[sake], flag: "", name: "Sake",
              check: "For Sake it first checks the program with `/home/ko1/app/sake/bin/sake --strict=2 -c` (this can take minutes on a large program; a program it rejects does not run), then runs each test at `--strict=0`.",
              note: "**Sake** (in `/home/ko1/app/sake`): Ruby syntax where every operation is written with its type (`String.upcase(s)`, not `s.upcase`). Learn it from `docs/tutorial.md` (start here), `docs/spec.md` and `docs/builtins.md`; these are the only documents you may read. Run a program with `/home/ko1/app/sake/bin/sake --strict=2 main.sake`." },
  "java" => { entry: "Main.java", exts: %w[java], flag: "", name: "Java (OpenJDK 21; the standard library is allowed)",
              check: "For Java it first compiles every `.java` file under `code/` with `javac` (a program that does not compile does not run), then runs each test with `java -cp <classes> Main`.",
              note: "**Java**: the entry is class `Main` in the default package (`code/Main.java`); other classes may be in packages in subdirectories of `code/`. No build tool and no library outside the JDK." },
  "haskell" => { entry: "Main.hs", exts: %w[hs], flag: "", name: "Haskell (GHC GHC_VERSION)",
                 check: "For Haskell it first compiles the program with `ghc -O1 -i<code dir> code/Main.hs` (a program that does not compile does not run), then runs each test with the binary.",
                 note: "**Haskell**: the entry is module `Main` in `code/Main.hs`; other modules live under `code/` in files named after them (`Engine/Parser.hs` for `Engine.Parser`). Only the packages that come with GHC are available (base, containers, mtl, text, bytestring, array, ...); no cabal or stack." },
  "scheme" => { entry: "main.ss", exts: %w[ss sls], flag: "", name: "Scheme (Chez Scheme 10, R6RS)",
                check: "For Scheme it runs each test with `scheme --libdirs <code dir> --program code/main.ss`, in `code/` as the current directory.",
                note: "**Scheme**: Chez Scheme 10. `code/main.ss` is an R6RS top-level program; put the other parts in R6RS libraries, e.g. `(engine parser)` in `code/engine/parser.sls`. Chez's own libraries (`(chezscheme)`) are allowed." },
  "steep" => { entry: "main.rb", exts: %w[rb rbs], flag: " --steep", name: "Ruby (4.0) type-checked with Steep",
               check: "With `--steep` it first type-checks the program with Steep (a program it rejects does not run): every `.rb` file under `code/` against the RBS signatures in `code/sig/`, with Steep's strict diagnostics, and any problem reported (warnings included) fails; so does `untyped` in a signature or a `steep:ignore` comment. Then each test runs with `ruby`.",
               note: "**Steep** (STEEP_VERSION, RBS RBS_VERSION): write an RBS signature for every class, module, method, instance variable and constant in `code/sig/*.rbs`, without `untyped`. Run the check alone with `ruby WORK_DIR/run_tests.rb WORK_DIR/code/main.rb --steep no-such-test` (it prints the check's result, then finds no test). Documents you may read: the README and `guides/`, `manual/`, `doc/` of the steep gem (`gem contents steep`) and `docs/` of the rbs gem, and the RBS signatures of the core library in the rbs gem's `core/`." },
}.freeze

run, lang, stage_s = ARGV
abort "usage: prep_p10.rb RUN #{LANGS.keys.join("|")} STAGE" unless run && LANGS.key?(lang) && stage_s
L = LANGS[lang]
stage = Integer(stage_s)
sql = File.join(AW::EXP, "large", "sql")
work = File.join(AW::EXP, "runs", run)
entry = L[:entry]

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
File.write(File.join(work, "meta.json"), JSON.pretty_generate({ run:, lang:, entry:, exts: L[:exts], flag: L[:flag].strip, stage: }))

versions = {
  "GHC_VERSION" => -> { `ghc --numeric-version`.strip },
  "STEEP_VERSION" => -> { `steep --version`.strip },
  "RBS_VERSION" => -> { `rbs --version`[/\d[\d.]*/] },
}
fill = ->(text) { versions.reduce(text) { |t, (k, v)| t.include?(k) ? t.gsub(k) { v.() } : t } }
name = fill.(L[:name])
new_note = stage == 1 ? "" : "Stage #{stage} (the last part, \"Stage #{stage}: ...\") is new in this task; stages 1..#{stage - 1} are what the program already does."
check_note = L[:check] || ""
code_note = stage == 1 ? "empty: the program goes here, entry `#{entry}`." : "the program so far, entry `#{entry}`, written by the previous stages; it passes every test of stages 1..#{stage - 1}."
job_note = stage == 1 ? "Write the program in `code/`, entry `#{entry}`: it reads a SQL script from standard input and runs it, as SPEC.md says." : "Extend the program in `code/` to stage #{stage}, keeping stages 1..#{stage - 1} working. Restructure what the new stage calls for."
lang_note = fill.(L[:note]).gsub("WORK_DIR") { work }
brief = File.read(File.join(AW::EXP, "brief-sql-build.md"))
prompt = brief.gsub("WORK_DIR") { work }.gsub("**LANG**") { "**#{name}**" }.gsub("STAGE") { stage.to_s }
              .gsub("code/main.EXT") { "code/#{entry}#{L[:flag]}" }.gsub("NEW_NOTE") { new_note }.gsub("CHECK_NOTE") { check_note }
              .gsub("CODE_NOTE") { code_note }.gsub("JOB_NOTE") { job_note }.gsub("LANG_NOTE") { lang_note }
prompt = prompt.gsub(/\n{3,}/, "\n\n").rstrip + "\n"
path = File.join(AW::EXP, "prompts", "#{run}-s#{stage}.md")
File.write(path, prompt)
puts path

# frozen_string_literal: true

# P11 (changes to the SQL engines): prepares one change task on one P10/P10b engine and writes its prompt.
#   ruby harness/prep_p11.rb MODE SRC CHANGE     e.g. prep_p11.rb t p10-sake-1 c1-collate
# MODE t: the solver has the stage 1-6 tests, the change's public tests (as tests/7) and run_tests.rb.
# MODE n: the solver has no tests and may not run anything; its only tool is harness/check_sql.rb
#         (the language's check: Sake -c, javac, ghc, Steep, ruby -wc, or reading every Scheme form).
# MODE h: as n, but CHANGE.md is the change's change-hard.md: the same rules stated by concept, with no list
#         of the places where the change applies (the solver must find them in the code).
# Creates runs/p11-MODE-LANG-N-CID/ (CID = c1 for c1-collate) with SPEC.md (stages 1-6), CHANGE.md,
# code/ (a copy of runs/SRC/stage-6/code), meta.json, and prompts/<run>.md.
require "fileutils"
require_relative "common"

LANGS = {
  "ruby" => { entry: "main.rb", exts: %w[rb], flag: "", name: "Ruby (4.0; the standard library is allowed)",
              check: "checks the syntax of every `.rb` file with `ruby -wc`" },
  "sake" => { entry: "main.sake", exts: %w[sake], flag: "", name: "Sake",
              check: "checks the program with `/home/ko1/app/sake/bin/sake --strict=2 -c` (this can take minutes)",
              test_check: "For Sake it first checks the program with `/home/ko1/app/sake/bin/sake --strict=2 -c` (this can take minutes on a large program; a program it rejects does not run), then runs each test at `--strict=0`.",
              note: "**Sake** (in `/home/ko1/app/sake`): Ruby syntax where every operation is written with its type (`String.upcase(s)`, not `s.upcase`). Learn it from `docs/tutorial.md` (start here), `docs/spec.md` and `docs/builtins.md`; these are the only documents you may read." },
  "java" => { entry: "Main.java", exts: %w[java], flag: "", name: "Java (OpenJDK 21; the standard library is allowed)",
              check: "compiles every `.java` file under `code/` with `javac`",
              test_check: "For Java it first compiles every `.java` file under `code/` with `javac` (a program that does not compile does not run), then runs each test with `java -cp <classes> Main`.",
              note: "**Java**: no build tool and no library outside the JDK." },
  "haskell" => { entry: "Main.hs", exts: %w[hs], flag: "", name: "Haskell (GHC GHC_VERSION)",
                 check: "compiles the program with `ghc -O1`",
                 test_check: "For Haskell it first compiles the program with `ghc -O1 -i<code dir> code/Main.hs` (a program that does not compile does not run), then runs each test with the binary.",
                 note: "**Haskell**: only the packages that come with GHC are available (base, containers, mtl, text, bytestring, array, ...); no cabal or stack." },
  "scheme" => { entry: "main.ss", exts: %w[ss sls], flag: "", name: "Scheme (Chez Scheme 10, R6RS)",
                check: "reads every form of every `.ss` and `.sls` file (a syntax check: it finds unbalanced parentheses and the like, and runs nothing)",
                test_check: "For Scheme it runs each test with `scheme --libdirs <code dir> --program code/main.ss`, in `code/` as the current directory.",
                note: "**Scheme**: Chez Scheme 10; Chez's own libraries (`(chezscheme)`) are allowed." },
  "steep" => { entry: "main.rb", exts: %w[rb rbs], flag: "--steep", name: "Ruby (4.0) type-checked with Steep",
               check: "type-checks the program with Steep: every `.rb` file under `code/` against the RBS signatures in `code/sig/`, with Steep's strict diagnostics; any problem (warnings included) fails, and so does `untyped` in a signature or a `steep:ignore` comment",
               test_check: "With `--steep` it first type-checks the program with Steep (a program it rejects does not run): every `.rb` file under `code/` against the RBS signatures in `code/sig/`, with Steep's strict diagnostics, and any problem reported (warnings included) fails; so does `untyped` in a signature or a `steep:ignore` comment. Then each test runs with `ruby`.",
               note: "**Steep** (STEEP_VERSION, RBS RBS_VERSION): keep an RBS signature for every class, module, method, instance variable and constant in `code/sig/*.rbs`, without `untyped`. Documents you may read: the README and `guides/`, `manual/`, `doc/` of the steep gem (`gem contents steep`) and `docs/` of the rbs gem, and the RBS signatures of the core library in the rbs gem's `core/`." },
}.freeze
MAX_CHECKS = 10

mode, src, change = ARGV
abort "usage: prep_p11.rb t|n|h SRC CHANGE" unless %w[t n h].include?(mode) && src && change
lang, series = src.delete_prefix("p10-").split("-")
L = LANGS.fetch(lang)
cid = change[/\Ac\d+/] or abort "bad change #{change}"
sql = File.join(AW::EXP, "large", "sql")
cdir = File.join(sql, "changes", change)
code_src = File.join(AW::EXP, "runs", src, "stage-6", "code")
abort "#{code_src} missing" unless File.directory?(code_src)
change_file = File.join(cdir, mode == "h" ? "change-hard.md" : "change.md")
abort "#{change_file} missing" unless File.exist?(change_file)
run = "p11-#{mode}-#{lang}-#{series}-#{cid}"
work = File.join(AW::EXP, "runs", run)
abort "#{work} exists" if File.exist?(work)

FileUtils.mkdir_p(work)
FileUtils.cp_r(code_src, File.join(work, "code"))
specs = Dir.glob(File.join(sql, "spec", "*.md")).sort
File.write(File.join(work, "SPEC.md"), "# A small SQL engine: specification, stages 1..6\n\n" + specs.map { File.read(_1) }.join("\n"))
FileUtils.cp(change_file, File.join(work, "CHANGE.md"))
entry = L[:entry]
flag = L[:flag]
if mode == "t"
  (1..6).each { |n| FileUtils.mkdir_p(File.join(work, "tests")); FileUtils.cp_r(File.join(sql, "tests", n.to_s), File.join(work, "tests", n.to_s)) }
  FileUtils.cp_r(File.join(cdir, "tests", "7"), File.join(work, "tests", "7"))
  FileUtils.cp(File.join(sql, "run_tests.rb"), work)
end
File.write(File.join(work, "meta.json"), JSON.pretty_generate({ run:, mode:, lang:, series:, src:, change:, entry:, exts: L[:exts], flag:, max_checks: MAX_CHECKS }))

versions = {
  "GHC_VERSION" => -> { `ghc --numeric-version`.strip },
  "STEEP_VERSION" => -> { `steep --version`.strip },
  "RBS_VERSION" => -> { `rbs --version`[/\d[\d.]*/] },
}
fill = ->(text) { versions.reduce(text) { |t, (k, v)| t.include?(k) ? t.gsub(k) { v.() } : t } }
cmd = "ruby #{work}/run_tests.rb #{work}/code/#{entry}#{flag.empty? ? "" : " #{flag}"}"
check_tool = "ruby #{AW::EXP}/harness/check_sql.rb #{work}"
if mode == "t"
  material = <<~M.rstrip
    - `tests/N/NNN-*.sql` with the expected standard output `.out`: the tests of stages 1-6 (`tests/1` ... `tests/6`)
      and the change's tests (`tests/7`).
    - `run_tests.rb`: `#{cmd}` runs them all (8 at a time) and reports each failure; add name
      substrings (`7/`, `3/012`) to run a subset, or `--check-only` to run only the language's check. #{L[:test_check]}
  M
  done = "Done means every test passes (`tests/1` ... `tests/7`). The change's tests do not cover every place where it " \
         "applies: the program will be judged by tests you do not see, on every place CHANGE.md lists and on stages 1-6, " \
         "so make the change wherever CHANGE.md says it applies, not only where the tests show."
  reply = "the test result"
else
  material = <<~M.rstrip
    - The check: `#{check_tool}` #{L[:check]}. You may use it at most #{MAX_CHECKS} times.
  M
  done = "In this task you cannot run anything: there are no tests, and running the engine or any part of it (or " \
         "loading its code into an interpreter or a REPL) is not allowed. Your only tool besides reading and editing " \
         "files is the check above, at most #{MAX_CHECKS} times. A program that fails the check cannot run, so it fails " \
         "every test. Done means you are confident the change is complete and correct; the program will be judged by " \
         "tests you do not see, on every place CHANGE.md lists and on stages 1-6."
  reply = "the last check's result"
end
change_note = mode == "h" ? "It states the change's rules; finding every place in the engine where they apply is part of the job." : "It ends with a list of where the change applies."
done = done.gsub("on every place CHANGE.md lists", "on every place the change reaches") if mode == "h"
note = fill.(L[:note] || "")
brief = File.read(File.join(AW::EXP, "brief-sql-change-solve.md"))
prompt = brief.gsub("WORK_DIR") { work }.gsub("**LANG**") { "**#{fill.(L[:name])}**" }.gsub("ENTRY") { "`#{entry}`".delete("`") }
              .gsub("CHANGE_NOTE") { change_note }.gsub("MODE_MATERIAL") { material }.gsub("MODE_DONE") { done }.gsub("MODE_REPLY") { reply }.gsub("LANG_NOTE") { note }
prompt = prompt.gsub(/\n{3,}/, "\n\n").rstrip + "\n"
path = File.join(AW::EXP, "prompts", "#{run}.md")
File.write(path, prompt)
puts path

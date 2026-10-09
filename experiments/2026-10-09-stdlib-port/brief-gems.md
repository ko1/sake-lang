# Brief: port well-known RubyGems to Sake (2026-10-09)

Goal (ko1): beyond Ruby's standard library (done: `sakelib/README.md`), make the popular gems available in Sake, and
report what one notices writing them: what could be ported, what could not and why, and how it felt to write
(書き心地). You port one group of gems into `sakelib/` of the repo `/home/ko1/app/sake`.

Read first: `sakelib/README.md`, `docs/tutorial.md` (skim), `docs/spec.md` (the rules), `docs/builtins.md` (every
built-in operation, including Ruby's whole core API, ENV, Open3, Zlib, Socket with TLS, Thread/Mutex/Queue,
IO positions, Record.to_h, at_exit). Sake is Ruby syntax where each operation names its type
(`String.upcase(s)`); calls on values (`s.upcase`) are rejected; blocks are second-class (passed to a call, or
on with `&b`, never stored); no `method_missing`/`define_method`/`send`; modules are mixins unless
`module_function`; a type is `class T` with `attr_reader`/`attr_accessor` fields and `T.new(...)` (positional or
by keywords); optional and keyword parameters exist; `require "x"` loads `sakelib/x.sake`. `bin/sake --strict FILE`
is the recommended level. Look at one existing port and its test (for instance `sakelib/strscan.sake`,
`test/sakelib/strscan.{sake,rb}`, `sakelib/notes/strscan.md`), and at `sakelib/minitest.sake` for how a DSL of
blocks is shaped in Sake.

## What to produce, per gem

1. `sakelib/<gem>.sake` (file name: the gem's name with `-` as `_`). Keep the gem's names where Sake allows:
   a module function stays one; a class becomes a type with its instance methods as operations taking the
   instance first; nested names are flattened (`ActiveSupport::Inflector.pluralize` → `Inflector.pluralize`,
   documented). Port the gem's commonly used API first (what its README shows), then more. Where the gem's
   design needs what Sake lacks (stored blocks, metaprogramming, monkey patches on core classes), design the
   closest Sake shape and explain it.
2. Tests: `test/sakelib/<gem>.sake` (a program exercising the API and printing results) and
   `test/sakelib/<gem>.rb`, the same program with the real gem **if it is installed** (`gem list`; do not install
   anything; no network). If the gem is not installed, write `test/sakelib/ref/<gem>.rb` instead: a plain-Ruby
   reference giving the expected output (as `test/sakelib/ref/semver.rb` does), and `test/sakelib/<gem>.rb`
   that requires it. The two outputs must be identical; `ruby test/test_sakelib.rb -n /<gem>/` checks it (the
   .sake runs with `--strict`). Where a gem's output is not reproducible (random, time, pid), seed or fix it.
3. Notes: `sakelib/notes/<gem>.md` with four sections:
   - **API**: a table of gem call → Sake call, "same" / "differs" / "missing".
   - **できたこと / できなかったこと**: what was ported, what could not be and the Sake rule behind it.
   - **書き心地** (the writing feel): what you wrote first → the message → what you wrote instead; where Sake
     was in the way and where it helped (the checker finding a real mistake, a shape that read as well as Ruby).
     Concrete, with the line of code. This section is a deliverable in itself.
   - **Built-ins requested**: each with a one-line justification.

## Rules

- Do NOT change `lib/`, `docs/`, `test/test_*.rb`, `sakelib/minitest.sake`, other groups' files, or anything
  outside your files listed above. If a built-in is missing, write it in Sake inside your library if you reasonably
  can; otherwise record it in your notes as a request.
- If you find an interpreter or checker bug, keep a minimal repro as `sakelib/notes/<gem>_bug_*.sake` and work
  around it.
- Shell commands need `dangerouslyDisableSandbox: true` (the sandbox fails here with a seccomp error).
- Do not run `git commit` or `git push`; leave the files in the working tree.
- Budget: about 2 hours for the group. If time runs short, stop adding API and finish the notes and the tests.
- When done, reply with under 300 words: per gem, what was ported (API count), what is missing and why, and the
  writing-feel points worth telling ko1.

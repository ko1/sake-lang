# Brief: port the rest of Ruby's standard library to Sake (2026-10-09)

Goal (ko1): make Sake usable like Ruby by porting Ruby's standard library. You port one group of libraries into
`sakelib/` of the repo `/home/ko1/app/sake`. 40 libraries are already there (`sakelib/README.md` lists them;
`sakelib/notes/*.md` are their notes); yours are new.

Read first: `sakelib/README.md`, `docs/tutorial.md` (skim), `docs/spec.md` (the rules), `docs/builtins.md` (every
built-in operation; it was extended today with most of Ruby's core API, including in-place forms such as
`String.upcase!` and `Array.map!`). Sake is Ruby syntax where each operation names its type (`String.upcase(s)`);
calls on values (`s.upcase`) are rejected. `require "json"` loads `sakelib/json.sake`. `bin/sake --strict FILE` is
the recommended level; `bin/sake --types FILE` shows the inferred types. Look at one existing port and its test
(for instance `sakelib/strscan.sake`, `test/sakelib/strscan.sake`, `test/sakelib/strscan.rb`, `sakelib/notes/strscan.md`)
to see the conventions.

## What to produce, per library

1. `sakelib/<lib>.sake`. Keep Ruby's names: a Ruby module function stays one (`Timeout.timeout(s) { }`); a Ruby
   class becomes a Sake type (`class StringIO` with `attr_reader`/`attr_accessor` fields) and its instance
   methods become operations with the instance first (`StringIO.read(io)`); `initialize` validates and sets
   defaults. Optional positional parameters work (`def f(a, b = 1)`); there are no keyword arguments (take an
   options Record, `{mode: "r"}`, as other ports do). Module functions called as `M.f(...)` need
   `module_function` in the module. Cover the commonly used API first, then more.
2. Tests: `test/sakelib/<lib>.sake` (a program exercising the API and printing results) and `test/sakelib/<lib>.rb`
   (the same program using Ruby's real library). The two outputs must be identical;
   `ruby test/test_sakelib.rb -n /<lib>/` checks it (the .sake runs with `--strict`). Include edge cases (empty
   input, errors raised and rescued). Where the output of Ruby's library is not reproducible (timestamps, pids,
   addresses), print something derived that is.
   Optionally also a `test/sake/<lib>_test.sake` written with `sakelib/minitest.sake` (see `test/sake/core_test.sake`).
3. Notes: `sakelib/notes/<lib>.md`: an API table (Ruby call → Sake call, "same" / "differs" / "missing"), what
   differs from Ruby and why (Sake's rules), what you could not port and why, built-ins you needed but Sake lacks
   (each with a one-line justification), and friction you hit, in the form: what you wrote first → the message →
   what you wrote instead. The friction list is a deliverable in itself: ko1 asked for a report of what one notices
   when using Sake.

## Rules

- Do NOT change `lib/`, `docs/`, `test/test_*.rb`, `sakelib/minitest.sake`, other groups' files, or anything
  outside your files listed above. If a built-in is missing, write it in Sake inside your library if you reasonably
  can; otherwise record it in your notes as a request (the maintainer adds built-ins afterwards).
- If you find an interpreter or checker bug, keep a minimal repro as `sakelib/notes/<lib>_bug_*.sake` and work
  around it.
- Shell commands need `dangerouslyDisableSandbox: true` (the sandbox fails here with a seccomp error).
- Do not run `git commit` or `git push`; leave the files in the working tree.
- Budget: about 90 minutes. If time runs short, stop adding API and finish the notes and the tests.
- When done, reply with under 250 words: what was ported (API count), what is missing and why, the top built-in
  requests, and the friction worth telling ko1 about.

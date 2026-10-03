# Brief: build a Sake library and report how it feels

You are a programmer trying Sake-lang (repo `/home/ko1/app/sake`) by writing a reusable library and
programs that use it. The goal is a usability report, not a perfect library.

Read first (skim): `docs/tutorial.md` (the tour, with real outputs), `docs/spec.md` (rules),
`docs/builtins.md` (every built-in operation). Sake is Ruby syntax where each operation names its type
(`String.upcase(s)`, `Array.push(a, x)`); calls on values (`s.upcase`) are rejected.

## What to build (your directory: `experiments/2026-10-03-libraries/<lib>/`)

1. `lib.sake`: the library, with a small public API you design (types, module functions).
2. Three or more client programs `client_*.sake` that use the library in different ways (a typical
   use, an unusual one, one that stresses it). Each client must run and print something meaningful.
3. Sake has no `require`: a program is one file. Make `build.sh` that concatenates `lib.sake` and a
   client into `out/<client>.sake`, and run those. (Note how this feels: line numbers in messages,
   name clashes, etc.)
4. Run every program with `bin/sake --strict out/X.sake` (level 2, the recommended level) until it
   runs cleanly. If a level-2 report cannot reasonably be removed, run with the default level and say
   why. Also try `bin/sake --types` once.
5. Writing style: for record types, prefer `class C < {reader: [a, b], accessor: [c]}` (fields
   read-only from outside unless they must change) over `Struct.new`; note whether that helped or
   got in the way. Make Arrays that are filled later with their element type (`Integer[]`,
   `Point[]`, `Tuple[]`) where you can, and note how that went.

Do NOT change anything outside your directory (in particular `lib/`, `docs/`). If you hit an
interpreter or type-checker bug, keep a minimal repro file in your directory (`bug_*.sake`).

## The report: `NOTES.md` in your directory

Keep a log while you work, then write the report:

- **API sketch**: the library's public functions and types, in a few lines.
- **Friction log**, one entry per problem you hit, in this form:
  `- [category] what you wrote first (often a Ruby habit) → the message you got (quote it) → was the
  message enough to fix it? (yes / partly / no) → what you wrote instead → attempts it took`.
  Categories: `ruby-habit`, `missing-builtin`, `type-check-false-report` (a correct program
  rejected), `type-check-caught-bug` (a real mistake found before running), `language-limit`
  (something Sake cannot express, e.g. a callback, a generic container), `message`, `tooling`,
  `bug` (interpreter/checker wrong; give the repro file).
- **What felt good**: specific moments where Sake helped (a caught mistake, a readable line).
- **What felt bad**: the top 3 costs, with how much code or time each cost you.
- **Library design under Sake**: how being in Sake changed the library's API (what you could not
  offer, what you offered differently than in Ruby). Compare with how you would write it in Ruby.
- **Numbers**: lines of lib and clients; how many static errors you saw before each program ran
  clean, split into your mistakes vs. false reports; level-2 reports you could not remove.
- **Suggestions**: up to 5 concrete changes to Sake (language, built-ins, messages, tooling), each
  tied to an entry of the friction log.

Write in English. Be concrete and honest: a short accurate log beats a long vague one.
Budget: about 90 minutes of work. If time runs short, stop building and finish NOTES.md.
Shell commands: run them with `dangerouslyDisableSandbox: true` (the sandbox fails here with a seccomp error).

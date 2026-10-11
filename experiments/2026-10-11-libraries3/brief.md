# Brief: port more libraries to Sake, side by side with Ruby (2026-10-11)

Goal (ko1): grow Sake's library so that Sake can be tried on more programs, and so that ko1 can compare the
Ruby code and the Sake code side by side. You port one group of libraries into `sakelib/` of the repo
`/home/ko1/app/sake`. About 75 libraries are already there (`sakelib/README.md`, notes in `sakelib/notes/*.md`);
yours are new. Ruby's real gem for each of yours is installed on this machine (`gem contents <gem>` shows its
files; read its source to port faithfully).

Read first: `docs/cheatsheet.md` (the rules and every operation, ~10k tokens; the most up-to-date summary),
`sakelib/README.md`, one existing port with its test and notes (for instance `sakelib/strscan.sake`,
`test/sakelib/strscan.sake`, `test/sakelib/strscan.rb`, `sakelib/notes/strscan.md`). `docs/spec.md` and
`docs/manual/ja|en/` have the details. `bin/sake --strict FILE` checks and runs; `bin/sake --types FILE` shows
the inferred types.

Current conventions (some are new this week; follow them):
- A Ruby class becomes `class Name` with `attr_reader` / `attr_accessor` lines (`Struct.new(:x, :y)` is the
  shorthand); its instance methods become operations with the instance first (`StringIO.read(io)`); inside, `@x`
  is the first argument's field. `initialize(obj)` validates and sets defaults.
- Namespaces nest like Ruby's: `module MessagePack; class Packer ... end; end`, called `MessagePack::Packer.pack(p, x)`,
  errors `MessagePack::MalformedFormatError`. Do not flatten names into `MessagePack_Packer`.
- `Enum` (the prelude) is Enumerable: `Enum.map(x) { }` dispatches to Array, Hash, Set, Range; a class joins
  with `include Enum` and `def each(x)`.
- `require "json"` loads `sakelib/json.sake`; `require "dir/*"` loads every .sake file in a directory.
- `def f = expr` only when expr is short (as in Ruby); longer bodies use `def ... end`.
- `include M` copies M's functions into the class; `M.f(x)` dispatches on x's type among the includers.
- There are no keyword arguments at call sites to Sake functions; take an options Record (`{indent: 2}`) or a Hash.

## What to produce, per library

1. `sakelib/<lib>.sake` (gem names with `-` become `_`: `protocol_hpack.sake`; `require "protocol_hpack"`).
   Keep Ruby's names and nesting. Cover the commonly used API first, then more.
2. Tests: `test/sakelib/<lib>.sake` and `test/sakelib/<lib>.rb`: the same program, once in Sake on your port and
   once in Ruby on the real gem, printing identical output; `ruby test/test_sakelib.rb -n /<lib>/` checks it (the
   .sake runs with `--strict`). **Write the two programs line by line in parallel** (same order, same variable
   names, same comments), because ko1 will read them side by side to compare the languages. Include edge cases
   and errors raised and rescued. Where Ruby's output is not reproducible (time, random, addresses), print
   something derived that is.
3. Notes: `sakelib/notes/<lib>.md`: an API table (Ruby call → Sake call, same / differs / missing), what differs
   and why (Sake's rules), what could not be ported and why, built-ins Sake lacks (one line each), and the friction
   you hit, as: what you wrote first → the message → what you wrote instead. Also the size: lines of the gem's
   Ruby source you ported vs lines of your Sake.

## Rules

- Do NOT change `lib/`, `docs/`, `bin/`, `tools/`, `test/test_*.rb`, `sakelib/README.md`, `sakelib/prelude.sake`,
  existing `sakelib/*.sake` files, or other groups' files. Another agent is editing existing sakelib files at the same
  time; touch only your own new files. If a built-in is missing, write it in Sake in your library if reasonable;
  otherwise record it in your notes as a request.
- If you find an interpreter or checker bug, keep a minimal repro as `sakelib/notes/<lib>_bug_*.sake`, work around it,
  and mention it in your reply.
- Shell commands need `dangerouslyDisableSandbox: true` (the sandbox fails here). The machine is shared and busy:
  do not run the whole test suite repeatedly; run `-n /<lib>/` for your own tests.
- Do not run `git commit` or `git push`; leave the files in the working tree.
- Budget: about 2 hours. If time runs short, stop adding API and finish the tests and the notes.
- When done, reply in under 300 words: per library the API count and Ruby-vs-Sake line counts, what is missing and
  why, the top built-in requests, any bugs found, and the friction worth telling ko1 about.

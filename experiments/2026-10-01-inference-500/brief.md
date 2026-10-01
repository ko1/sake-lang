# Brief for corpus writers

You write small, realistic programs in **Sake** and the same programs in **Ruby**. They are used to
measure how much a type inferencer can infer from programs written without any type annotations.
Write the programs the way a programmer would naturally write them for the task. Do **not** simplify
or reshape a program to make types easier, and do not avoid features the task calls for (indexing,
Hash lookups that may miss, `find`/`first`/`min` that may return nil, Structs, modules, operators on
your own types, exceptions, pattern matching, ...).

## Learning Sake

Sake is Ruby syntax where every operation is written with its type: `String.upcase(s)`, not
`s.upcase`. Read these, in the repository `/home/ko1/app/sake`:

- `docs/tutorial.md` (start here), `docs/spec.md`, `docs/builtins.md` (all built-in operations).

Do **not** read `lib/`, `DESIGN.md`, `experiments/` (other than this brief and your own directory),
or `test/`. Do not modify anything outside your own directory.

## Running

- Sake: `bin/sake --strict=0 PROG.sake` (from `/home/ko1/app/sake`). Always use `--strict=0`:
  it turns off the type checker that runs before the program, which is what is being measured.
  Never use `--types` or other `--strict` levels.
- Ruby: `ruby PROG.rb` (Ruby 4.0).
- The Bash sandbox in this environment is broken; run Bash commands with `dangerouslyDisableSandbox: true`.

## Requirements for each program

- 40-250 lines of Sake (a soft limit; the Ruby version may be longer). Do not cut features the task
  needs to fit the limit. Self-contained: data is embedded in the program; no input, no ARGV, no
  files, no randomness, no current time. Deterministic output. Each run should finish within a few seconds
  (the Sake interpreter is much slower than Ruby: aim for under 5 s per Sake run; shrinking the
  input data for that is fine).
- It must exit with status 0 under `bin/sake --strict=0`, and `ruby PROG.rb` must print exactly the
  same output (byte-identical). Adjust the printing in either version if formatting differs, but keep
  the algorithm the same in both.
- The Ruby version is idiomatic Ruby (method calls on values, blocks, etc.), with no type
  annotations, RBS, or comments about types. For record-like types in Ruby, write a plain `class`
  with `attr_reader`/`attr_accessor` and `initialize` (not `Struct.new`/`Data.define`). Exceptions are
  `class FooError < StandardError` (add `attr_reader` and `initialize` calling `super(message)` if they
  carry data). Functions that belong to a Sake type (`Point.norm(p)`) become methods (`p.norm`) in Ruby;
  top-level Sake functions stay top-level methods.
- Each version is written the natural way for its language: the Ruby version is idiomatic Ruby (it may
  use `break` in blocks, array patterns, etc.) and only the Sake version works around what Sake lacks.
- Use only the features each language has. If Sake cannot express something, find the Sake way
  and record it in NOTES.md (below); do not drop the feature from the task.

## Output files (in your directory `corpus/<NN-domain>/`)

- `<slug>.sake`, `<slug>.rb` for each task (slug: lowercase, `_`-separated, unique in your directory).
- `<slug>.out`: the standard output of `bin/sake --strict=0 <slug>.sake` (identical to Ruby's; nothing
  should be written to stderr).
- `TASKS.md`: one line per task: `- <slug>: <one-sentence description>`.
- `NOTES.md`: per task, only if something notable happened: Sake errors you hit and how you fixed
  them (quote the first line of the message), things Sake could not express and the workaround,
  and anything that looks like an interpreter bug (with a minimal reproduction). Keep it short.

At the end, from `/home/ko1/app/sake`, verify every task with a loop like:
`for f in corpus/<NN-domain>/*.sake; do ...; done` checking exit status 0 and `diff` against Ruby.

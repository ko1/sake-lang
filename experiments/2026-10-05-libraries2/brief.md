# Brief: write many Sake libraries with the current language

Repo `/home/ko1/app/sake` (Sake-lang: Ruby syntax; each operation names its type, `String.upcase(s)`;
no types on variables, parameters or fields). Read first: `docs/spec.md` (all of it; recent additions:
§6 parameters incl. optional / keyword / `*rest` / `**opts`, §7 blocks incl. `block_given?` and `&b`,
§9.1 `x => T`, §10.1 class + `attr_reader x` / `attr_accessor n = Array[]` (any expression default) /
`private attr_*` / `initialize(c)` / `class B < A` / `T.new(a, k: v)` keywords, field readers `T.x(v)` /
`v.T.x`, writes `v.T.x = w` and `v.T.x += 1`), `docs/tutorial.md`, `docs/builtins.md` (skim), and
`sakelib/README.md` plus one existing library and its notes (e.g. `sakelib/json.sake`,
`sakelib/notes/json.md`) to see the conventions. Do not read `lib/` or `DESIGN.md`.

## For each library of your group

1. `sakelib/<name>.sake`: the library, with Ruby's API where Ruby has one (a Ruby module function stays
   one: `Pathname.join(p, q)`; a Ruby class becomes a Sake class with its instance methods taking the
   instance first). Use what a Ruby author would use: keyword arguments, `initialize` for validation,
   `once` for constant tables, `x => T` where Ruby raises on a wrong type, `private attr_*` for internal
   state, expression defaults, `*rest`.
2. Tests: `test/sakelib/<name>.sake` (exercise the API, print results; edge cases, errors rescued) and
   `test/sakelib/<name>.rb`, the same program in Ruby. When the library exists in Ruby's standard
   library, use it; otherwise write an idiomatic pure-Ruby reference implementation in
   `test/sakelib/ref/<name>.rb` and `require_relative "ref/<name>"` from the test. The two outputs must be
   identical: `ruby -Ilib test/test_sakelib.rb -n /<name>/` (it runs the .sake with `--strict`, i.e.
   level 2; findings there make the test fail, so they count). Run only your own libraries' tests.
3. `sakelib/notes/<name>.md`: an API table (Ruby call → Sake call, same / differs / missing), what
   differs from Ruby and why, frictions (what you wrote first → message → what you wrote instead), the
   new language features you used, the findings of `bin/sake --strict=1 -c` and `--strict=2 -c` on your
   test before you made it pass (if any, and how you fixed them), and the types `bin/sake --types
   test/sakelib/<name>.sake` reports as unions or unknown for fields and functions, with the reason.

Rules: do not change `lib/`, `docs/`, `test/test_*.rb`, or files of other libraries (another agent is
editing existing sakelib libraries at the same time; only create your own files). If you find a bug in
Sake, keep a minimal repro at `sakelib/notes/<name>_bug_*.sake` and work around it. No git. Shell commands
need `dangerouslyDisableSandbox: true`. Budget about 90 minutes. Reply in under 250 words: per library,
API size and status; the frictions that cost the most; bugs found; and, for each new feature, whether it
helped (with one example).

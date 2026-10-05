# Brief: review the corpus programs against Sake's current language

Repo: `/home/ko1/app/sake`. You review some domains of `experiments/2026-10-05-review/corpus-v3/`, a copy
of the 500-program corpus written on 2026-10-01 (each task: `NAME.sake`, the same program in idiomatic Ruby
`NAME.rb`, and the expected output `NAME.out`). Since then the language changed. Read first (in this
order): `docs/spec.md` (the whole spec; the newest parts are §6 Parameters, §7 Blocks, §9.1 Pattern
matching, §10.1 Declaring a type, and "IO values", "once", "Program arguments"), `docs/tutorial.md`, and
`docs/builtins.md` (skim). Do not read `lib/` or `DESIGN.md`.

What changed (all in the docs):
- Fields are declared in the class body: `attr_reader x, y`, `attr_accessor n = 0`, `attr_writer w`
  (names bare). The programs were converted mechanically from the old `class C < {reader: [...]}` form.
  A default is only an initial value: it does not fix the field's type.
- `def initialize(c)` runs after `C.new` has stored the fields: checks and conversions.
- `class B < A` writes A's definitions in B (not inheritance: a B is not an A).
- `class E < Exception` with `attr_reader` lines declares an exception type.
- Optional parameters `def f(a, b = 1)`, keyword parameters `def f(a, k: 1, r:)`, `f(k:)` shorthand.
- `x => Integer` asserts a type (Ruby's rightward pattern match); `x => {a:, b:}` as before.
- `block_given?`, and `def f(xs, &b) = g(xs, &b)` to pass a block on.
- `once { ... }` for a value computed once (tables), in place of constants.
- IO values: `IO.stdout`, `IO.stderr`, `IO.stdin`, `File.open(path, mode) { |f| ... }`, `IO.puts(io, ...)`.
- Built-ins: `String.index(s, t, start)`, `Regexp.match(re, s, pos)`, `sub`/`gsub` with a Hash or a block,
  `String.byteslice`, `unpack`, `Array.pack`, `warn`, `exit`, `ARGV`.

## Your job, per program

1. Read the `.sake` and its `.rb`. Rewrite the `.sake` where the new language lets it say what the Ruby
   version says more directly: the Ruby version is the reference for "natural". Typical cases:
   - a `Struct.new` record that Ruby wrote as a class with `attr_reader`: use `class` + `attr_reader`
     (reader for fields not changed from outside).
   - a helper with an extra parameter that Ruby wrote as an optional or keyword argument, or two
     functions that exist only because a parameter could not be omitted.
   - validation or conversion that Ruby does in `initialize`, or a check the Sake version did by hand.
   - Ruby `CONSTANT = [...]` tables that the Sake version rebuilt in a function on every call: `once`.
   - a Ruby class hierarchy that the Sake version flattened: `class B < A` where it is only code reuse
     (never where Ruby relies on a B being an A; keep the module/dispatch form there).
   - Ruby's `raise ArgumentError unless x.is_a?(Integer)`: `x => Integer`.
   Do not add things the Ruby version does not have; do not rewrite what is already natural. Leave a
   program unchanged when nothing fits.
2. Run it: `bin/sake --strict=0 PROGRAM.sake` (from the repo root; level 0 = no type checks before
   running). Its output must be identical to `NAME.out` (stdout; and exit status 0). **Do not run with
   `--strict` or `--types`, and do not change a program to please the type checker**: the experiment
   measures the checker on programs written as a programmer would, blind to it.
3. Do not edit the `.rb` or `.out` files, or files outside your domains.

## Notes to write

For each domain, `corpus-v3/<domain>/REVIEW.md`: one line per program (`name: unchanged` or
`name: <what changed, by feature>`), then a short section "Friction": where the current language still
made the Sake version clumsier than the Ruby one (what you wanted to write → why you could not → what you
wrote), and "Ruby comparison": what differs in shape from the Ruby version that a Ruby programmer would
notice first. Be concrete (file:line).

Shell commands need `dangerouslyDisableSandbox: true`. Do not use git (no stash, checkout, commit).
When done, reply in under 200 words: per domain, programs changed / unchanged, the features used most,
and the top frictions.

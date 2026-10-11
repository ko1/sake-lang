# Audit of the documents (2026-10-11)

Scope: README.md, docs/ (spec, tutorial, cheatsheet, guide sources, manual ja/en incl. ref/),
examples/README.md, sakelib/README.md, ide/README.md, outdated hints in lib/sake/*.rb.
Every claim was checked with `bin/sake` before it was changed.

## Changes

README.md
- "Not yet: ... built-in constants such as `Math::PI`" → `Math::PI` works (read as `Math.PI`); only
  `case`/`when` and first-class blocks remain.
- Modules bullet: "There is no inheritance" → `include M` copies; `class B < A` copies A's
  definitions, no inheritance (a B is not an A).
- Repository layout: ranges.rb, sakelib/ (prelude with Enum), test/native/.

docs/spec.md
- §3: what a class/module body may contain now includes `module_function`, nested `class`/`module`,
  `Name = Struct.new(...)` / `Exception.new(...)`. Constants: `Struct.new` *or* `Exception.new`.
- §3: `def name = expr` is for a short expression.
- §5.4: unqualified calls search only the innermost namespace (inside `A::B`, `A`'s function is
  `A.f`); types/constants are looked up outward. "Struct accessors" → field readers and writers.
- §10.1: example `attr_accessor balance = 0` contradicted "no default values" → `attr_accessor balance`.
- §10.1: "`<` takes a class (or a `Struct.new` type)" → any class, also `Struct.new(...)` in place.
- §10.2: "Struct.new must be assigned to a top-level constant" → a constant at the top level or
  directly in a class/module body (`Geo::Point` works).
- §12: "`{}` ... errors, because a Hash is not available yet" → errors with a hint to `Hash[]`.
- "Struct value(s)" → "class instance(s)" (5 places).

docs/tutorial.src.md (→ tutorial.md regenerated)
- Playground: "build it in ide/" → the Pages URL.
- `def f(x) = expr`: for a short expression.
- New short sub-sections in §8: Nested namespaces, Enum.
- "a `class` that is not a type ... reported" (no longer an error: a class without fields is a
  type) removed; docs/examples/module_errors.sake drops its `class Helpers`, which no longer errs.
- "A Struct's field" → "A class's field"; exceptions: `class E < Exception` first, `Exception.new`
  as the shorthand; bank example: "(`reader:`)" → "(`attr_reader`)".

docs/guide.src.html (→ guide.html regenerated)
- Same playground, `reader:`, Struct-field/value, class-not-a-type fixes; "A class without fields
  is an error" → every class is a type.
- Not yet supported: Tuple patterns `[P, Q]` exist now (only `*rest`, find, pins, guards remain).
- Notation table: `require "sql/*"` glob, nested namespaces row, Enum row.
- Unqualified names: innermost namespace only. `def f = expr` for short expressions.

docs/cheatsheet.src.md (→ cheatsheet.md regenerated)
- `Math.PI` (also `Math::PI`); `def f(x) = expr` (short expressions only); the long one-line
  `def print` in the example became `def ... end`.

docs/manual (ja and en)
- 02: unqualified calls: innermost namespace only; "Struct accessors" → field readers/writers.
- 04: one-line `def` is for short expressions.
- 07: `Struct.new` constant may be inside a class/module body; `<` takes any class.
- 09: "no other nested names" → no other built-in constants (`A::B` is a namespace, not a value).
- a1: `Math::PI` row gives `Math.PI` (or `Math::PI`). ref/Math: `Math::PI` also readable.
- "Struct value(s)" / "Struct 値" → "class instance(s)" / "クラスのインスタンス" in 07, ref/Array,
  Kernel, Set, Tuple, Hash, Record (Ruby's own "Struct values" left as is).

ide/README.md: completion lists `new`, `x` / `set_x` (not `get_x`); Types shows the fields of classes.
sakelib/README.md: mentions prelude.sake (Enum). No library entries added or removed.

lib/sake/resolver.rb (message text only)
- `class B < M` hint: "to borrow a module's functions" → "to copy" (test/samples/class_settings_errors.expected updated).
- "Struct.new must be assigned to a top-level constant" → "to a constant (at the top level or in a class/module body)".

## Left alone
- examples/README.md: its corpus notes are dated records (2026-10-10); nothing current was wrong.
- docs/comparison.md: no factual error about Sake found (axis L already covers nesting and Enum).
- Long but single-expression endless defs in docs/examples (types.sake `total`, once.sake): changing
  them would shift generated line numbers for little gain.
- The cheatsheet's "Ported:" library list (other agents are adding libraries).

## Looked wrong in the language
- The static error for `PI = 3.14` says "only a class made with Struct.new can be assigned to a
  constant", but `E = Exception.new(:x)` is allowed too (message kept: the manual quotes it).
- Functions are not looked up outward from a nested namespace while types are; consistent with the
  code but easy to trip on (the hint `A.helper()` helps).

## Checks
`ruby test/test_cli.rb` 7/7, `ruby test/test_samples.rb` 167/167, `sh docs/manual/build.sh` built
(45+45 chapters), `ruby tools/check_reference.rb` 32 chapters, 0 problems.

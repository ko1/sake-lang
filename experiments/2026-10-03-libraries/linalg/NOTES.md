# linalg: vectors and matrices in Sake, a usability report

Files: `lib.sake` (260 lines), `client_exact.sake`, `client_transform.sake`, `client_fib.sake`,
`client_stress.sake`, `client_gram.sake`, `build.sh`, `bug_case_else_not_pruned.sake`,
`bug_types_raise_error.sake`. `./build.sh` concatenates and runs every client with `--strict`; all five
run cleanly at level 2 (and at `--strict=3`, checked for `client_exact`). Output: `out/run.txt`.

## API sketch

- `Vec` (`class Vec < {reader: [elems]}`, includes Arithmetic, Indexable):
  `Vec.of(array)`, `Vec.zero(n)`, `Vec.size`, `v[i]`, `v[i] = x`, `Vec.to_a`, `v + w`, `v - w`, `-v`,
  `v * k` (scale) / `v * w` (dot), `v / k`, `Vec.dot`, `Vec.exact` (to Rational), `to_s`.
- `Mat` (`class Mat < {reader: [nrows, ncols, rows]}`, includes Arithmetic, Indexable):
  `Mat.of(rows)`, `Mat.build(n, m) { |i, j| }`, `Mat.identity(n)`, `Mat.zero(n, m)`, `m[i, j]`,
  `m[i, j] = x`, `Mat.at`, `Mat.row`, `Mat.col`, `Mat.map { }`, `Mat.transpose`, `m + n`, `m - n`, `-m`,
  `m * n` / `m * v` / `m * k`, `m ** k`, `Mat.det` (Bareiss for all-Integer, pivoted elimination
  otherwise), `Mat.solve(a, b)` → Vec or nil, `Mat.inverse(a)` → Mat or nil, `Mat.exact`,
  `Mat.to_float`, `to_s`.
- helpers: `la_abs(x)`, `la_exact(x)`, `la_fmt(x)`, `la_promote(x)`. Integer input to `solve`/`inverse`
  is promoted to Rational, so the answer is exact; Float stays Float.

Clients: exact 3x3 system + Hilbert(4) inverse vs. Float solve (typical); 2D homogeneous transform
pipeline in Floats, inverse round trip, `rotate(1) ** 360` drift; Fibonacci and graph walks via
Integer `**`, Cassini via `det`; a 12x12 Integer system where Bareiss, Rational and Float determinants
are cross-checked (values agree with Ruby's `Matrix#det`); exact Gram-Schmidt and a projection matrix
(unusual; exercises the vector operators and indexing).

## Friction log

- [ruby-habit] `(k + 1).upto(n - 1) do |i|` (7 places in lib) → `method call on a value `(k + 1).upto`
  is not allowed / hint: Integer.upto((k + 1), n - 1) { ... }` → yes → `Integer.upto(k + 1, n - 1)` →
  1 attempt. Because of the concatenation, the same 7 errors were printed once per client (28 lines).
- [missing-builtin] `la_exact(x)` as `(Integer|Rational).to_r(x)` (probe: `Rational.to_r`) →
  `undefined function `Rational.to_r` ... hint: `to_r` is defined in `Integer.to_r`, `Float.to_r`,
  `String.to_r`` → yes (the hint told me exactly what exists) → `x + 0r` → 1 attempt.
- [type-check-caught-bug] Vec `+`, `-`, `dot` via `Array.zip(@elems, Vec.get_elems(b))` →
  `Arithmetic.*: the operands may be nil ([Float | nil | Integer | Rational, ...]) [nil] / hint:
  Vec.elems may be nil (nil is stored at line 116)` → partly. True that `zip` pads with nil for a
  shorter Array (only `dot` checked the sizes), but the "nil is stored at line 116" hint pointed at
  `Mat.apply`, which stores the result of `dot`; the actual nil source was `Vec.get_elems(b)[i]`
  (index can miss) in `Mat.solve`, which I only found with `--types`. → rewrote with a size check and
  `Array.fetch` (`Vec.zip_with`) and `Array.fetch` in solve → 2 attempts.
- [type-check-caught-bug] `width = Array.max(...)` passed to `String.rjust` → `String.rjust: argument 2
  may be nil (Integer | nil) [nil]` → yes → `Array.max(...) || 0` → 1 attempt.
- [bug] `def *(a, b)` with `case b in Mat ... in Vec ... else Mat.map(a) { ... } end`; client
  `b = a * xs` (xs a Vec), then `Mat.solve(a, b)` → `Vec.get_elems: argument 1 must be Vec, but can be
  Mat [type]` reported inside `solve` → no: the program is correct. The `else` branch is not dropped
  even when the `in` branches cover the subject's type, so the result of `a * v` is `Mat | Vec`.
  Repro: `bug_case_else_not_pruned.sake`. → replaced `else` with `in Integer | Float | Rational then`
  (in both Vec and Mat) → ~20 minutes to bisect the 260-line lib down to 12 lines.
- [language-limit] `client_stress`: `Rational.denominator(e)` for entries of `Mat.inverse(a)` (a is
  Integer, so entries are Rational) → `Rational.denominator: argument 1 must be Rational, but can be
  Float | nil | Integer [type]` → yes, but the report is about the library being generic: element
  types are one union per field (`Vec.elems`, `Mat.rows`) for the whole program, so a "Mat of
  Rational" cannot be told from a "Mat of Float". → `(e in Rational) ? Rational.denominator(e) : 1`
  → 2 attempts (next entry).
- [ruby-habit] `e in Rational ? a : b` → `syntax error: unexpected '?'` → partly (same as Ruby; the
  message does not mention `in`) → `(e in Rational) ? ... ` → 1 attempt.
- [missing-builtin] `Math::PI` → `unsupported syntax: constant path `Math::PI`` → partly (no hint for
  pi) → `Math.atan(1) * 4` → 1 attempt.
- [missing-builtin] `Float.max(worst, x)` (not Ruby either, my guess) → `undefined function
  `Float.max` / hint: `max` is defined in `Array.max`, ...` → yes → `worst = e if e > worst`.
- [language-limit] `2 * v` → `Arithmetic.*: the operands are (Integer, Vec), which the left operand's
  type does not support [type]` → yes, clear. No `coerce`/right-operand dispatch, so scalars go on the
  right only (`v * 2`). Not changeable from the library side.
- [message] mistaken calls (`Mat.solve(a, Array[1, 2])`, `a * "x"`, `Mat.det(Array[...])`) → 8 errors,
  all located inside lib.sake (`Mat.get_nrows: argument 1 must be Mat, but is Array@L264[...]`) with
  "reached by the call at line 264 → line 145" → partly: the bug is caught before running, which is
  great, but the client line is in a hint, and the `case/in: no `in` branch matches String` one for
  `a * "x"` has no "reached by" hint at all, so the client line is missing.
- [tooling] `--types` on a correct program prints `error L25 raise arg ArgumentError: want a rescue,
  got ArgumentError` for every `raise ArgumentError, "msg" if ...` (9 of them) →
  `bug_types_raise_error.sake` (5 lines). `--strict` is fine with it.
- [tooling] Type errors in library functions no client calls are not reported at all (checked:
  `def f(x) = String.upcase(1)` uncalled → exit 0). `--types` lists them as "dead functions"; with one
  client, half of the API (`Vec.+`, `Mat.transpose`, `Mat.**`, ...) was unchecked. I wrote
  `client_gram` partly to exercise them.
- [tooling] `build.sh` concatenation: lib lines keep their numbers (lib first), client lines are offset
  by 260, so `out/client_x.sake:285` needs subtraction to find the client line.

## What felt good

- Operator overloading on my own types just worked: `translate(5, 0) * rotate(90) * scale(2, 2)`,
  `w - u * ((w * u) / (u * u))` (Gram-Schmidt in one line, mixing scalar `*` and dot `*`), `m[i, j] =`
  with two indexes, `p * p == p`, `Mat.transpose(p) == p` (Struct equality by content for free).
- Numeric genericity is free at the element level: the same `det`/`solve` code ran on Integer,
  Rational, Float, and a mixed `[[1, 1/2r], [0.5, 3]]` matrix. Exact Rational results (Hilbert inverse,
  det = 1/6048000, 12x12 det = -196351073792) needed no extra code beyond `x + 0r`.
- `client_gram` (35 lines, most API surface) ran clean at `--strict` on the first try.
- `--types` was the best debugging tool: it found the real nil source (`@rows[i], @rows[j] =
  @rows[j], @rows[i]` reads that may miss, and `[i]` in solve) and showed `Vec.elems: nil | ...`; after
  the fix it reports `partial=0`.
- The "did you mean / defined in" hints (`to_r`, `Float.max`, `.upto`) fixed every name error in 1 try.

## What felt bad (top 3)

1. The `else`-not-pruned bug in `case` (the natural way to write "m * matrix / vector / scalar"):
   a false report far from the cause, ~20 minutes to bisect; workaround is to list scalar types.
2. One element type per field for the whole program: a generic container cannot promise its client
   "this Mat is Rational", so a client that needs Rational-only operations (`denominator`) must `case`
   on each element (1 line here, but it is the general case for any generic library). `Integer[]`/
   `Rational[]` typed rows would defeat the genericity, so I used `Array.new`/`Array.map` throughout.
3. Checking only reached code + concatenation: lib errors repeated per client, client line numbers
   offset, and uncalled API unchecked. About 10 minutes plus a fifth client to cover the API.

## Library design under Sake

- Scalars only on the right (`v * 2`, not `2 * v`); in Ruby I would define `coerce`. `*` is
  overloaded by `case` on the right operand (Mat / Vec / scalar), as Ruby's Matrix does.
- No `Matrix[[...]]` constructor sugar: `Mat.of(Array[Array[1, 2], Array[3, 4]])`; `[[1, 2], [3, 4]]`
  is a Tuple of Tuples. `Mat.build(n, m) { |i, j| }` works as in Ruby.
- `Mat.solve`/`inverse` return nil for a singular matrix instead of raising, which level 2 then forces
  the client to check (`if x`) — a good fit.
- `Rational` has no `to_r`, so exactness is `x + 0r` instead of `x.to_r`; Integer is promoted to
  Rational inside solve/inverse (Ruby's Matrix does `quo`), since Integer `/` would truncate.
- Free functions (`la_abs`, `la_fmt`) are prefixed by hand, because the concatenated program is one
  namespace; in Ruby they would be private methods. A `module Linalg; module_function` would also work.
- `reader:` for all fields: fine, since mutation goes through the inner Arrays (`m[i, j] =`);
  `swap_rows!` writes `@rows[i]` inside the class. It neither helped nor got in the way.
- Typed Arrays: `Vec[pt(0, 0), ...]` and `out = Vec[]` in clients worked well; inside the lib no
  element type could be written (generic).

## Numbers

- Lines: lib 260; clients 38 (exact) + 35 (transform) + 15 (fib) + 32 (stress) + 35 (gram) = 155.
- Static errors before each ran clean (mine / false reports). The 7 `.upto` errors in lib were printed
  for every client; counted once per client here:
  - client_exact: 10 (7 upto, 2 zip-nil, 1 rjust-nil) / 0
  - client_fib: 8 (7 upto, 1 rjust-nil) / 0
  - client_stress: 9 (7 upto, 1 zip-nil, 1 syntax) / 2 (else-not-pruned bug; Rational-only op on a
    generic element)
  - client_transform: 9 (7 upto, Math::PI, Float.max) / 0
  - client_gram: 0 / 0
- Level-2 reports I could not remove: none. Runtime errors after a clean check: none.

## Suggestions

1. Drop a `case` `else` branch (and its result type) when the `in` branches already cover the
   subject's type (friction: [bug] else-not-pruned). This is the idiomatic shape of an overloaded
   operator.
2. Report a type error at the outermost call site in the user's code first, with the library line as
   the hint, and always add "reached by" for `case/in` errors (friction: [message] mistaken calls).
3. Add `Rational.to_r` (and `Float.to_f`, `Integer.to_i`-style identities) so generic numeric code can
   write `(Integer|Float|Rational).to_r(x)`; add `Math.pi`/`Math::PI` (friction: Rational.to_r, PI).
4. A `--check-all` (or a default warning) that type-checks uncalled functions with their most general
   inputs, or at least lists them as "unchecked" in `--strict` output; and a way to concatenate files
   while keeping per-file line numbers (`# line` directive or a `--lib` flag) (friction: [tooling]).
5. Fix `--types` classifying `raise ArgumentError, "msg"` as an error (friction:
   bug_types_raise_error.sake).

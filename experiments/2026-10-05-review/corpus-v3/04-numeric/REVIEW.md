# Review: 04-numeric (corpus-v3, against the language at 2026-10-05)

All 25 programs give `NAME.out` exactly with `bin/sake --strict=0` (exit 0).

- bezier_curves: unchanged (Ruby destructures in the parameter list, `def lerp((px, py), (qx, qy), t)`; see Friction).
- correlation_matrix: Ruby's `DATASET` constant (rebuilt by `dataset` on each call) -> `def dataset = once do Hash[...] end`; `Array.map(xs) { 0.0 }` -> `Array.new(Array.size(xs), 0.0)`.
- cubic_spline: `OutOfRange` -> `class OutOfRange < StandardError` + `attr_reader x`; `Spline = Struct.new` -> `attr_reader xs, ys, m` in the existing `class Spline`.
- curve_fitting: `NotPositiveDefinite` -> exception class; `Range.map(0...n) { Range.map(0...n) { 0.0 } }` -> `Array.new(n) { Array.new(n, 0.0) }` (as Ruby).
- descriptive_stats: `Sample` -> `class Sample` + `attr_reader`.
- eigenvalues: `NotConverged` -> exception class; `tmp` swap of rows -> `m[c], m[p] = m[p], m[c]`; `Array.map(a) { 1.0 }` / `Array.map(b) { 0.0 }` -> `Array.new(n, v)`; trace via `Range.reduce` -> `Range.sum(0...n) { ... }` (as Ruby).
- float_accuracy: `Summer` Struct + `Summer.zero` factory -> `class Summer` with `attr_accessor sum = 0.0, comp = 0.0` and `Summer.new` (Ruby's `initialize(sum = 0.0, comp = 0.0)`); `Array.concat(Array[1.0e16], Range.map(1..2000) { 1.0 })` -> `Array[1.0e16] + Array.new(2000, 1.0)`; `Range.map(1..2000) { 0.1 }` -> `Array.new(2000, 0.1)`.
- fourier_spectrum: `Array.map(xs) { |x| x }` -> `Array.dup(xs)` (Ruby `xs.dup`).
- gaussian_elimination: `SingularMatrix` -> exception class; three `tmp` swaps -> multiple assignment to elements; `Array.new(n, v)` twice; augmented row built by a push loop -> `Array.dup(a[i]) + Range.map(0...n) { ... }` (as Ruby).
- histogram_fit: `Lcg` -> `attr_reader state` in its class; `Bin` -> `class Bin` + `attr_accessor lo, hi, count` (as Ruby); `each_cons` block `|p0, p1|` + two destructuring lines -> `|(x0, d0), (x1, d1)|` (as Ruby).
- interval_arithmetic: `DivideByZeroInterval` -> exception class; `left, right = split; push(left, right)` -> `Array.push(queue, *Interval.split(box)) if ...` (Ruby `queue.push(*box.split)`); `pop` + `push` -> `found[-1] = ...`.
- linear_regression: `Obs`, `Fit` -> classes with `attr_reader`.
- loan_amortization: `Loan`, `Row`, `NoSolution` -> classes with `attr_reader`.
- lu_decomposition: `SingularError` -> exception class; `LU` -> `attr_reader a, perm, sign` in its class; two 3-line swaps -> multiple assignment.
- matrix_ops: `DimensionError` -> exception class; `def [](m, ij)` taking a Tuple, used as `m[[i, j]]` -> `def [](m, i, j)` / `def []=(m, i, j, v)` and `m[i, j]` everywhere (two indexes, as Ruby); `zeros` -> `Array.new(r * c, 0.0)`; `from_rows` concat loop -> `Array.flatten(rows)` (as Ruby); `trace` -> `Range.sum`.
- monte_carlo: unchanged (already `attr_accessor n = 0, ...` for Ruby's optional `initialize` parameters).
- numeric_integration: `adaptive`, `adaptive_simpson`, `romberg` re-yielding through `{ |x| yield(x) }` -> `&f` passed on (Ruby's `&f`); `gauss_nodes` table (Ruby `GAUSS_NODES`) -> `once`; `Problem` -> class + `attr_reader`.
- numerical_derivatives: `richardson` -> `&f` passed on to `central_diff` (local `f` renamed `fac`, as Ruby).
- ode_solver: `State` -> `class State` + `attr_accessor t, y` (as Ruby); `integrate`'s three `{ |tt, yy| yield(tt, yy) }` -> `&f`.
- optimization: `nelder_mead(..., &f)` with `Array.sort_by(pts, &f)` and `Array.min_by(pts, &f)` (Ruby `sort_by(&f)`, `min_by(&f)`).
- polynomial: `Range.map(0..k) { 0.0 }` -> `Array.new(k + 1, 0.0)` (2 places, as Ruby).
- root_finding: `NoConvergence`, `BadBracket` -> exception classes; `Result` -> class + `attr_reader` (field kept as `method`: Ruby renamed it `method_name` only to avoid `Object#method`).
- special_functions: `PoleError` -> exception class; `lanczos_coeffs` (Ruby `LANCZOS`, rebuilt on every `gamma` call) -> `once`; the 3-line `if ... raise ... end` -> modifier `raise ... if` (as Ruby).
- time_series: `Reading` -> class + `attr_reader`.
- vector_geometry: `Triangle` Struct + reopened class -> one `class Triangle` with `attr_reader`.

Summary: 23 changed, 2 unchanged. Most used: `class` + `attr_*` (17 programs; 10 exception classes),
`Array.new(n, v)` / `Array.new(n) { }` (8), `&f` block forwarding (4), multiple assignment to elements
for swaps (3), `once` for Ruby constants (3), `Range.sum` with a block (3), Array + Array (3),
`m[i, j]` two-index `[]` (1). No program needed `x => T`, keyword/optional parameters, `initialize` or
`class B < A`: the Ruby versions here use only one optional-parameter `initialize`, expressed by
`attr_accessor` defaults.

## Friction

- **Compound assignment with two indexes.** matrix_ops.sake:140. Wanted Ruby's `h[3, 3] += 0.001` →
  static error "`h[3, 3] += 0.001` takes one index", although `m[i, j]` and `m[i, j] = v` both work →
  wrote `h[3, 3] = h[3, 3] + 0.001`.
- **`Array.fetch` has no default.** polynomial.sake:14. Ruby: `@coeffs.fetch(i, 0.0)` → builtins list
  only `Array.fetch(x, Integer)` → kept `Array.fetch(@coeffs, i) rescue 0.0` (Hash.fetch has the default).
- **A block taken as `&f` cannot be called.** numeric_integration.sake:23-47, optimization.sake:62-91.
  Ruby calls `f.call(x)` and passes `&f` on; in Sake `f` is only for `&f`, so the same function uses
  `yield(x)` to call and `&f` to pass on. Works, but the two spellings of one block sit side by side.
- **Destructuring parameters.** bezier_curves.sake:1-11, 93-96. Ruby `def lerp((px, py), (qx, qy), t)`
  → a `def` parameter cannot be a pattern (block parameters can) → `px, py = p` lines in each function.
- **No `Math::PI` / `Float::EPSILON` / `Math::E`.** `def pi = 3.141592653589793` is repeated in four
  files (fourier_spectrum:1, monte_carlo:32, numeric_integration:1, special_functions:5), plus literals in
  vector_geometry:30 and numerical_derivatives:77. Could be `once`, but a literal needs no `once`.
- **`@x` reaches only the first argument.** Every binary operator on a value type reads the other operand
  through its accessors: vector_geometry.sake:6-18 (`Vec3.get_x(b)` x 9), interval_arithmetic.sake:17-38,
  optimization.sake:4-5, fourier_spectrum.sake:8-13.
- **No enumerator chaining.** time_series.sake:14-37 (`each_cons(w).map` → push into `out`),
  special_functions.sake:139 / time_series:110 (`zip(drop(xs, 1), xs)` for `each_cons(2).map`),
  bezier_curves.sake:16,44,64 (`Range.map` over indexes), ode_solver (`each_index.map` → `Range.map`).

## Ruby comparison

- `self.factory` class methods and instance methods look the same: `def make(cs)` (polynomial),
  `def build(xs, ys)` (cubic_spline), `def zeros(r, c)` (matrix_ops) take no instance yet sit in the
  class next to `def at(p, x)`; only the parameter name tells them apart.
- Operator definitions have an explicit left operand: `def +(a, b)` where Ruby has `def +(b)` and `self`.
- Method calls on results nest inside-out: Ruby `(r.power(4) - Matrix.identity(2)).frobenius` is
  `Matrix.frobenius(Matrix.power(r, 4) - Matrix.identity(2))` (matrix_ops.sake:133).
- `Float[...]` / `Tuple[...]` on literal tables (gaussian_elimination, numeric_integration's `Tuple[...]`)
  where Ruby writes `[...]`; a Ruby reader sees element types where Ruby has none.
- Exception classes lose Ruby's `initialize(message, x)` + `super(message)` boilerplate entirely.

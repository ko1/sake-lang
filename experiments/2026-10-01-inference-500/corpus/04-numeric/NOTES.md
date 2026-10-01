# Notes for 04-numeric

## general (applies to most tasks)
- No `Math::PI` / value constants: `def pi = 3.141592653589793` (Ruby side uses `Math::PI`); constant tables such as Gauss nodes become zero-arg functions.
- No unary minus on expressions: `-Math.sin(x)` is written `0.0 - Math.sin(x)`.

## numeric_integration
- Blocks are not values, so recursive/forwarding integrators that Ruby writes with `&f` re-wrap the block at each level: `adaptive(...) { |x| yield(x) }`. Works, but each recursion level adds a block frame.
- Mutable counter shared through recursion: a one-element Tuple `[3]` updated with `counter[0] += 2` (Ruby uses an Array the same way).

## matrix_ops
- `m[i, j]` is rejected: "`m[1, 0]` takes one index" (also for `[]=` and `+=`). Workaround: index with a Tuple, `m[[i, j]]`, and `i, j = ij` inside `def [](m, ij)`.
- "Range.sum does not take a block": `(0...n).sum { ... }` written as `Range.reduce(0...n, 0.0) { |acc, i| ... }`.
- `self[i, k]` inside Ruby methods becomes `a[[i, k]]` on the explicit subject parameter.

## gaussian_elimination
- Row swap `m[col], m[pivot] = m[pivot], m[col]` is rejected: "only `a, b = tuple` (local variables, no splat) is supported". Written with a temporary local (three statements per swap).
- `Array.each_with_index` without a block (Ruby's `each_with_index.map`) is not available; rewritten with `Range.map(0...n)` / `Range.reduce` over indices.
- Reading one field of a returned Record (`solve(h, b)[:x]` in Ruby) is a pattern: `solve(h, b) => {x:}`.
- `Array.new(n, 0.0)` does not exist; `Array.map(rhs) { |v| 0.0 }` / `Range.map(0...n) { 1.0 }`.

## ode_solver
- Choosing the stepper by Symbol (`case method in :euler then euler_step(...) { |tt, yy| yield(tt, yy) }`): each branch re-wraps the block, where Ruby forwards `&f`.
- `!rising` written `rising == false` (no unary operators).

## time_series
- Enumerator chains (`xs.each_cons(w).map`, `each_with_index.map`, `each_index.max_by`) have no Sake form; written as `Array.each_cons` pushing into an `Array[]`, or `Range.to_a(0...n)` then `Array.max_by`.

## histogram_fit
- Nested destructuring block parameters (`each_cons(2) do |(x0, d0), (x1, d1)|`) are not available; the block takes the window Array and does `x0, d0 = pair[0]`.
- `bins[idx].count += 1` on a Struct field becomes `Bin.set_count(b, Bin.get_count(b) + 1)`.

## polynomial
- `Array#fetch(i, default)` has no Sake form (`Array.fetch(x, Integer)` only); written `Array.fetch(@coeffs, i) rescue 0.0`.
- `Array.new(n, 0.0)` replaced by `Range.map(0..n) { 0.0 }`.

## eigenvalues
- No `loop do ... end`: written `while true ... break if ... end`.
- `row.dup << bi` (push returning the array) written `Array.push(Array.dup(row), bi)`, which also returns the array.

## lu_decomposition
- `sign = -sign` written `sign = 0 - sign`; swaps of rows and permutation entries via temporaries (see gaussian_elimination).

## optimization
- Possible inconsistency: `Array.include?(found, [1.0, 2.0])` on an Array of Tuples works (true), but `[1.0, 2.0] == [1.0, 2.0]` raises "TypeError: Kernel.==: no implementation for (Tuple, Tuple)". spec §8.1 says `include?` uses the same equality as `==`. Repro: `f = Array[[1.0, 2.0]]; p(Array.include?(f, [1.0, 2.0])); p([1.0, 2.0] == [1.0, 2.0])`.
- First version (5000 gradient-descent iterations) took ~22 s CPU in Sake; reduced to 400 iterations.

## monte_carlo
- First version (2000 walkers x 40 steps, 4000-point pi, 3000-sample integrals) took ~10 s CPU in Sake (~0.1 s in Ruby); sample sizes were cut by about 3x.
- Ruby's optional constructor arguments (`Welford.new` with `n = 0, mean = 0.0, m2 = 0.0`) map directly to `default: {n: 0, mean: 0.0, m2: 0.0}`.

## correlation_matrix
- Ruby's constant `DATASET = {...}` becomes `def dataset = Hash[...]` (no value constants, `{...}` is a Record).

## float_accuracy
- `Float::INFINITY` -> `1.0 / 0.0`, `Math::E` -> `Math.exp(1.0)`, `-inf` -> `0.0 - inf`, `x.infinite?.inspect` -> `Kernel.inspect(Float.infinite?(x))`.
- The FloatDomainError message differs from Ruby: Sake says "Float.to_i: NaN", Ruby says "NaN". Printing changed to not show the message.
- First version (20000-term series, sorting, three summations each) took ~24 s CPU in Sake; series cut to 2000-3000 terms (~2 s).

## interval_arithmetic
- Ruby's `queue.push(*box.split)` (splat of a returned pair) written `left, right = Interval.split(box); Array.push(queue, left, right)`.
- Mixed operands (`a + 1`, `a * 0.5`) handled by a `lift` that pattern-matches `Interval | Float | Integer`, same in both versions; `poly_f` is shared between Float and Interval arguments (polymorphic function).

## bezier_curves
- Ruby destructuring parameters (`def dist((px, py), (qx, qy))`, `each_with_index do |(px, py), i|`) are rejected in Sake; each function starts with `px, py = p`.
- First version (256-segment polylines, adaptive tolerance 1e-6 depth 20) took ~15 s CPU in Sake; reduced to 128 segments, 1e-4 / depth 12 (~3 s).

## numerical_derivatives
- `x, y = v` on an Array (Ruby) raises in Sake: "TypeError: multiple assignment needs a Tuple, got Array". The point is a `Float[...]` Array (it is copied with `Array.dup` and written by index), so it is read as `x = v[0]; y = v[1]`.
- `Float::EPSILON` written as the literal `2.220446049250313e-16`; `10.0 ** -k` as `10.0 ** (0 - k)`.

## curve_fitting
- `Model.describe(m)` / `Model.predict(m, x)` were rejected: "undefined function `Model.describe`" with hint "`describe` is defined in `PolyModel.describe`, `ExpModel.describe`". Only functions defined in the module dispatch, so a function the module merely requires from its includers cannot be called through the module. Workaround: one-line forwarding mixin functions `def label(m) = describe(m)` and `def fitted(m, x) = predict(m, x)` in `Model`. Ruby calls `m.describe` directly.

## loan_amortization
- `(1.0 + r) ** -months` written `** (0 - months)` (no unary minus on a variable).

## verification (2026-10-01)
- All 25 tasks: `bin/sake --strict=0` exits 0 with empty stderr, and stdout is byte-identical to `ruby X.rb` and to `X.out`. Sake wall time 0.3-3.7 s per task on a shared, loaded machine.
- Environment: one run in the middle failed with a SyntaxError inside `lib/sake/resolver.rb` (someone was editing lib/ at the same time); rerunning a few minutes later passed with no changes on my side.

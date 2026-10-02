# Changes for 04-numeric (corpus-v2)

15 of 25 programs changed. Every program exits 0 under `bin/sake --strict=0`, and its output is byte-identical to `<slug>.out`.

- bezier_curves: unchanged (destructuring parameters `def dist((px, py), (qx, qy))` are still rejected, so `px, py = p` stays)
- correlation_matrix: unchanged
- cubic_spline: unchanged
- curve_fitting: the forwarding mixin functions `Model.label` / `Model.fitted` are removed; `(PolyModel|ExpModel).describe(m)` and `(PolyModel|ExpModel).predict(best, 6.0)` are called directly (list the types on the operation). `wx, wr = Array.max_by(...)` now destructures the result directly, with no `worst` temporary
- descriptive_stats: unchanged
- eigenvalues: unchanged (row swap still needs a temporary; still no `loop`)
- float_accuracy: unary minus: `(0.0 - b + d)` / `(0.0 - b - d)` -> `(-b + d)` / `(-b - d)`, `0.0 - inf` -> `-inf` (twice)
- fourier_spectrum: unary minus: `conj` uses `-@im`; the sort key `0.0 - a` -> `-a`
- gaussian_elimination: unary minus: `det = 0.0 - det` -> `det = -det` (row swaps still use temporaries)
- histogram_fit: unary minus `Math.exp(-ax * ax)`; `Array.each_cons(dens, 2) do |p0, p1|` takes the window Array apart in the block parameters, replacing `pair[0]` / `pair[1]`
- interval_arithmetic: `while Array.empty?(queue) == false` -> `until Array.empty?(queue)` (as in Ruby)
- linear_regression: unary minus in the sort key: `-Fit.predict(f, 23.0)`
- loan_amortization: `** (0 - months)` -> `** -months`; `by_year` reads `paid, interest = years[y] || [0.0, 0.0]` (as in Ruby) instead of a nil check on a temporary
- lu_decomposition: `sign = 0 - sign` -> `sign = -sign` (row and permutation swaps still use temporaries)
- matrix_ops: unchanged (`m[i, j]` is still rejected, and so is `Range.sum` with a block)
- monte_carlo: unary minus: `Math.exp(-x * x)` (twice)
- numeric_integration: unchanged (still forwards the block with `{ |x| yield(x) }`)
- numerical_derivatives: `10.0 ** (0 - k)` -> `10.0 ** -k`; Array destructuring `x, y = v` and `px, py = pt` replace the index reads
- ode_solver: unary minus `Float[y[1], -y[0]]`; `rising == false` -> `!rising`
- optimization: unchanged (the `[1.0, 2.0] == [1.0, 2.0]` inconsistency from the first round is gone, but the code never relied on it)
- polynomial: unary minus `Float[-r, 1.0]` (twice); `Array.fetch(...) rescue 0.0` stays (`Array.fetch` has no default argument)
- root_finding: unary minus `-Math.sin(x) - 1.0`
- special_functions: unary minus: `Math.exp(-t)`, `Math.exp(-x * x)`, `-erf(-x)`, and `term = -term * ...` (twice)
- time_series: unchanged (still no Enumerator chains such as `each_cons(w).map`)
- vector_geometry: unchanged

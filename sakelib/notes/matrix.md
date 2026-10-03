# matrix (Matrix, Vector)

`sakelib/matrix.sake` ports Ruby's `matrix` gem (0.4.3). It has about 68 public Matrix operations and 36
Vector operations. Determinant (the expanded forms for sizes up to 4, then Bareiss), inverse
(Gauss-Jordan with `quo`), rank, and `**` are ported line by line, so Integer, Rational, and Float
results match Ruby, including the last bits of Float. Test: `test/sakelib/matrix.sake` and `.rb`, about 190
lines of output that match Ruby's at `--strict`. The test also passes at `--strict=3`.

Types: `class Matrix < {reader: [rows, column_count]}` and `class Vector < {reader: [elements]}`. Both
include `Arithmetic` (so `+ - * / ** -@ +@` work) and `Indexable` (so `m[i, j]`, `m[i, j] = x`, `v[i]`,
and `v[i] = x` work). `==` is the built-in Struct equality, which compares the same fields as Ruby's
`Matrix#==` (`rows` and `column_count`), so 1 == 1.0 holds element by element. Matrices therefore stay
usable as Hash keys. Exceptions are the top-level types `ErrDimensionMismatch`, `ErrNotRegular`,
`ErrOperationNotDefined`, and `ZeroVectorError`, and their messages are Ruby's.

## API

| Ruby | Sake | |
|---|---|---|
| `Matrix[[1, 2], [3, 4]]` | `Matrix.rows(Array[Array[1, 2], Array[3, 4]])` | differs: `T[...]` is "Array of T" in Sake |
| `Matrix.rows(rows)` / `Matrix.columns(cols)` | `Matrix.rows(rows)` / `Matrix.columns(cols)` | same (the `copy` flag is missing; rows are always copied) |
| `Matrix.build(r, c) { \|i, j\| }` | `Matrix.build(r, c) { \|i, j\| }` | same (no default for `c`, no Enumerator form) |
| `Matrix.identity(n)`, `unit(n)` | same | same (`Matrix.I` is missing) |
| `Matrix.zero(n)` | `Matrix.zero(n)` | same; `Matrix.zero(r, c)` is missing (no optional parameters): use `Matrix.build(r, c) { 0 }` |
| `Matrix.scalar(n, v)` | same | same |
| `Matrix.diagonal(1, 2, 3)` | `Matrix.diagonal(Array[1, 2, 3])` | differs: user functions take no rest parameter |
| `Matrix.row_vector(a)`, `column_vector(a)` | same | same (Array or Vector) |
| `Matrix.empty(r, c)` | `Matrix.empty(r, c)` | same (both arguments are required) |
| `Matrix.vstack(a, b, ...)`, `hstack` | `Matrix.vstack(a, b)`, `hstack(a, b)` | differs: exactly two |
| `m[i, j]`, `element`, `component` | `m[i, j]`, `Matrix.element(m, i, j)`, `component` | same (nil outside the matrix) |
| `m[i, j] = v` | `m[i, j] = v` | same for Integer indexes; the Range forms are missing |
| `row_count`, `row_size`, `column_count`, `column_size` | `Matrix.row_count(m)`, ... | same |
| `row(i)`, `column(j)` | `Matrix.row(m, i)`, `Matrix.column(m, j)` | same (Vector, or nil outside); the block forms are missing |
| `row_vectors`, `column_vectors`, `to_a` | same | same |
| `each { }`, `each_with_index { \|e, i, j\| }` | `Matrix.each(m) { }`, `Matrix.each_with_index(m) { }` | same for `:all`; the `which` argument (`:diagonal`, `:strict_upper`, ...) is missing |
| `map { }`, `collect { }` | `Matrix.map(m) { }`, `Matrix.collect(m) { }` | same (no `which`) |
| `minor(r, nr, c, nc)` | `Matrix.minor(m, r, nr, c, nc)` | same; the Range form `minor(0..1, 0..1)` is missing |
| `first_minor`, `cofactor`, `adjugate` | same | same |
| `+ - *` (Matrix, Vector, number), `/` (number, Matrix) | same operators | same |
| `2 * m` | `m * 2` | differs: an operator dispatches on its left operand, and there is no `coerce` |
| `m ** k` (Integer k, including negative) | `m ** k` | same; a non-Integer exponent (which needs eigensystem) is missing |
| `-m`, `+m` | same | same |
| `hadamard_product`, `entrywise_product` | same | same |
| `transpose`, `t` | same | same |
| `determinant`, `det` | same | same |
| `inverse`, `inv` | same | same (Integer entries give Rationals, as in Ruby) |
| `rank`, `trace`, `tr` | same | same |
| `round(n)` | `Matrix.round(m, n)` | same (n is required); Rational entries are rounded in Sake, because `Rational.round` takes no digits |
| `square?`, `empty?`, `zero?`, `diagonal?`, `upper_triangular?`, `lower_triangular?`, `symmetric?`, `antisymmetric?`, `orthogonal?`, `permutation?`, `singular?`, `regular?` | same | same |
| `==`, `!=` | same | same |
| `to_s`, `inspect` | `puts(m)`, `p(m)` | same text |
| `to_matrix` | same | same |
| `hermitian?`, `normal?`, `unitary?`, `real?`, `conj`, `imaginary`, `real`, `rect` | | missing (Complex-specific; not ported for time) |
| `eigensystem`/`eigen`, `lup`/`lup_decomposition` | | missing (the largest remaining parts) |
| `laplace_expansion(row:)`, `rotate_entries`, `combine`, `index`, `freeze`, `collect!`, `coerce`, `hash`, `eql?`, `abs`, `elements_to_*` | | missing |
| `Vector[1, 2]` | `Vector.elements(Array[1, 2])` | differs (as for Matrix) |
| `Vector.elements(a)`, `Vector.zero(n)` | same | same |
| `Vector.basis(size: 3, index: 1)` | `Vector.basis(3, 1)` | differs: no keyword arguments |
| `v[i]`, `v[i] = x`, `element`, `component` | same | same for Integer indexes (no Ranges) |
| `size`, `to_a`, `each`, `each2`, `map`/`collect`, `map2`, `collect2` | same | same |
| `+ - * /`, `-v`, `+v` | same | same (Vector * Vector raises ErrOperationNotDefined, as in Ruby) |
| `inner_product`, `dot` | same | same (conjugates a Complex right operand) |
| `cross_product(w)`, `cross` | `Vector.cross_product(v, w)` | same for 3 dimensions; Ruby's `cross_product(*vs)` for other sizes is missing |
| `magnitude`, `norm`, `r`, `normalize` | same | same |
| `angle_with(w)` | same | same, except within about 1 ulp: Sake has no `Math.acos`, so it uses `atan2(sqrt(1 - x²), x)` |
| `zero?`, `covector`, `to_matrix`, `round(n)`, `==` | same | same |
| `Vector.independent?`, `independent?`, `collect!`, `hash`, `coerce` | | missing |

## Differences and their reasons

- **No `Matrix[...]` or `Vector[...]`.** `T[...]` builds an Array of T, which is a static meaning of the
  syntax, so `Matrix[[1, 2]]` reports `Matrix[]: an element must be Matrix, but is Array`. Construction
  goes through `Matrix.rows` and `Vector.elements`, which Ruby also has.
- **Fixed arity.** Sake functions take no optional, rest, or keyword parameters. So `Matrix.zero(r, c)`,
  `Matrix.build(n)`, `Matrix.diagonal(*vs)`, `vstack(*ms)`, `Vector.basis(size:, index:)`, and `each(which)`
  each use one fixed form, chosen as the most common one.
- **Scalars go on the right.** `2 * m` is `Integer.*(2, m)`. Integer's `*` does not take a Matrix, and
  there is no `coerce`, so only `m * 2` works.
- **Exceptions are top-level names.** Ruby's `Matrix::ErrDimensionMismatch` and
  `Vector::ZeroVectorError` cannot be nested, because Sake has no `A::B`.
- **Element types are one union per program** (see Friction). Ruby allows a `Matrix` of Strings and
  `m.collect(&:to_s)`. In Sake you can build one, but once any matrix in the program holds Strings,
  every arithmetic operation in matrix.sake is reported as `(Integer, String) not supported`. The test
  therefore does not do this.

## Built-ins Sake lacks (requests)

- `Math.acos` (and `asin`): `Vector.angle_with` needs it, and the `atan2` workaround is not bit-exact
  with Ruby.
- `Integer.quo` / `Numeric#quo`: Ruby's `inverse` relies on `Integer#quo(Integer)` → Rational. I wrote it as
  `Integer.to_r(a) / b` inside `Matrix.quo`.
- `Rational.round(r, digits)`: `Matrix#round(n)` on Rational entries needs it (done by hand).
- `Complex.abs2`: `Vector#magnitude` uses `abs2` (done by hand).
- `Math::PI` (or `Math.pi`): I wrote `Math.atan(1) * 4`, which happens to equal π exactly in IEEE doubles.
- (language) right-operand dispatch or `coerce`, so that `2 * m` can work.

## Friction

- First, `test/sakelib/matrix.sake` with `require "matrix"` gave `undefined type or module Matrix`, because
  the test file required itself. I worked around it with `require "../../sakelib/matrix"`. The
  coordinator's loader fix removed the problem, and the test is back to `require "matrix"`.
- `size = rs.Array.first&.Array.size || 0`: I did not try `&.`, and wrote `first == nil ? 0 : Array.size(first)`
  instead.
- `show("collect", Matrix.collect(a) { |e| Integer.to_s(e) })` in the test gave dozens of `[type]` reports
  inside matrix.sake, such as `Arithmetic.*: the operands may be (Integer, String), ...` with the hint
  "reached by the call at line N". The reports were all correct but far from the cause: one String
  matrix anywhere makes the `rows` field `Array of (Integer | ... | String)` in every function. I removed
  that line from the test. A generic container in Sake works only if the whole program uses one kind of
  element. This is the same finding as experiments/2026-10-03-libraries/linalg/NOTES.md.
- `Matrix.column` built a Vector from `r[j]`, which may be nil, and that nil showed up in every
  arithmetic report (`(nil, Integer)`). Fix: `Array.fetch(r, j)`, since `j` was already range-checked.
- `def [](m, i, j)` was first written as `row = @rows[i]; row == nil ? nil : row[j]`. Then, in a client,
  `x = m[0, 0]; x + 1` gave `Arithmetic.+: the operands may be nil [nil]` at level 2, while `a[0] + 1`
  on an Array is only reported at level 3. The reason is that my code returned a literal `nil`, which
  the checker treats as a real nil. Writing `(@rows[i] || Array[])[j]` makes the nil come only from
  indexing, so a user's `m[i, j]` is now treated like `a[k]` (level 3, `index-nil`). It is not a checker
  bug, but a library author has to know this to get Ruby's leniency.
- `Vector.angle_with`: `if Matrix.abs(dot) >= prod` gave `Comparable.>: the operands may be (Complex,
  Integer)`, because one test vector held Complex numbers, so every `inner_product` result may be
  Complex. Fix: `case dot in Complex then raise ... in Integer | Float | Rational ...`.
- `Matrix.round` gave `case/in: no in branch matches Complex`, for the same reason. I added a branch for
  Complex that raises.
- Test: `Float.round(Vector.angle_with(...), 10)` gave `argument 1 must be Float, but can be Integer`.
  That is correct: as in Ruby, `angle_with` returns the Integer 0 for parallel vectors. I wrote
  `(Integer|Float).round(x, 10)` instead.
- Not friction: the earlier author's `case ... else` bug (experiments/.../bug_case_else_not_pruned.sake)
  is fixed now, so `m * v` has the type Vector and `m * m` the type Matrix.

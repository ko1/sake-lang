# Review: 13-polymorphism (corpus-v3, 2026-10-05)

The `.rb` symlinks in this directory point to `../../corpus/...`, which does not exist under
`2026-10-05-review/`. The Ruby versions were read from
`experiments/2026-10-01-inference-500/corpus/13-polymorphism/`.

Every program defines its exception types as `class E < StandardError` with `attr_reader` and an
`initialize(message, ...)`, so each `E = Exception.new(:f)` became `class E < Exception` with
`attr_reader f` (listed below as "exception class"). All 25 programs give their `.out` with
`bin/sake --strict=0` and exit 0.

- bitset_permissions: exception class; `flag_names` and `roles` wrapped in `once` (Ruby `FLAG_NAMES`/`ROLES`; `roles` was rebuilt, including 5 `Bits.of` calls, on every `effective` call).
- calendar_dates: exception class; `weekday_names` and `holidays` in `once` (`holidays` re-parsed 5 dates on every `business_day?` call); `cur += 1` / `d += 1` instead of `x = x + 1`.
- collision_check: `Body = Struct.new(...)` became `class Body` + `attr_accessor` (Ruby has `attr_accessor`, and `shape` is set from outside).
- color_palette: exception class; `def hue(a) = hsl(a)[0]` instead of destructuring into three locals.
- doc_render: `Array.sum(doc) { ... }` instead of `Array.sum(Array.map(doc) { ... })`.
- duration_timesheet: exception class; `Entry` Struct.new became `class Entry` + `attr_accessor`.
- expr_tree: exception class only.
- fraction_math: exception class; `rest -= unit`.
- interval_arith: exception class; `Array.sum(busy) { ... }`.
- life_grid: two-index operators `def [](g, r, c)` / `def []=(g, r, c, v)` and `g[r, c]` instead of a Tuple index `g[[r, c]]` taken apart in the operator; `Array.new(h) { Array.new(w, false) }` instead of nested `Range.map`; one `Array.map` for the chomped lines.
- matrix_ops: exception classes (`SingularError` too, now raised as `raise SingularError, "..."` as Ruby does); two-index `[]`/`[]=` (`m[i, j]`); row swap by parallel assignment `rows[pivot], rows[col] = rows[col], rows[pivot]` instead of a temp; `det *= ...`; `Range.sum(0...3) { ... }` for the trace.
- modint_combinatorics: exception classes; compound assignment in `lucas` (`result *=`, `n /=`, `k /=`) and `crt` (`x +=`, `modulus *=`).
- money_ledger: exception classes; `rates` in `once`; `Txn` Struct.new became `class Txn` + `attr_accessor`; `Array.sum(parts) { ... }`; `total_usd += usd`.
- notify_channels: exception class; `Message` Struct.new became `class Message` + `attr_accessor`.
- payroll: `brackets` in `once`; tax loop ends with `break` from the block, then one `Float.round(tax)`, as Ruby (was `return Float.round(tax)` inside the block); `Array.sum(staff) { ... }` twice.
- physical_quantities: exception class; `named_units` and `prefixes` in `once` (both Hash tables rebuilt on every `unit_s`/`parse` call); `name, pow = String.split(tok, "^")`; `value *= factor ** exp`.
- polynomial: `Array.new(n, 0)` instead of `Range.map(0..n-1) { 0 }` (twice); `result *= a`, `q += term`, `r -= term * b`.
- quaternion_rotation: `Body` Struct.new became `class Body` + `attr_accessor`.
- shapes_area: `Array.sum(shapes) { ... }`.
- sparse_vector: `stopwords` Set in `once` (it was rebuilt for every word).
- stack_vm: exception classes; `VM = Struct.new` plus a reopened `class VM` became one `class VM` with `attr_accessor` and `@stack`/`@pc` inside (`def advance(vm) = @pc += 1`, as Ruby); `op, arg = String.split(l, " ")`.
- task_heap: `swap` by parallel assignment `@items[i], @items[j] = @items[j], @items[i]`, as Ruby.
- temperature_units: exception class; removed the hand-written `Temp.==` (Comparable with `<=>` now gives `==`, as Ruby's Comparable); `Reading` Struct.new became `class Reading` + `attr_accessor`; `Array.sum(temps) { ... }`.
- vector_polygon: modifier form `Array.pop(lower) while ...`, as Ruby.
- version_constraints: exception class; `Requirement` Struct.new plus a reopened class became one `class Requirement` with `attr_accessor` and `@op`/`@version`/`@parts` instead of `get_op(r)`; `break if y == nil` in `compare_pre`, as Ruby (was `next`, with the same result).

No program used optional or keyword parameters, `block_given?`, `initialize`, or `x => Integer`: none
of the Ruby versions has default arguments, validation in `initialize`, or `is_a?` checks that raise.
`class B < A` was not used: there is no Ruby class hierarchy here, only modules.

## Friction

- **Compound assignment through a two-index operator.** matrix_ops.sake:192: I wanted `m[2, 0] += 7`
  (Ruby line 199) → static error "`m[2, 0] += 7` takes one index", although `m[2, 0]` and
  `m[2, 0] = v` both work → wrote `m[2, 0] = m[2, 0] + 7`.
- **Mixin needs a stub for every field it reads.** payroll.sake:7-8 and 39/49/64/77: Ruby's
  `Payable#stub` calls `name` and `dept`, which each class gets from `attr_reader`. In Sake the
  accessor is `get_name`, so `Payable` declares `def name(e) = raise(...)` and every class repeats
  `def name(e) = @name` and `def dept(e) = @dept` (8 one-liners). `attr_reader` cannot satisfy a
  module's function.
- **Array patterns.** collision_check.sake:53-69: Ruby's `case [a, b] in [Circle, Box]` (rb:69-78)
  becomes nested `case` with 7 branches; the `[Dot, _]` / `[_, Dot]` arms are duplicated.
- **No `Hash.dup`.** sparse_vector.sake:22,28: Ruby `@entries.dup` → `Hash.merge(Hash[], @entries)`
  (`Array.dup` exists, `Hash.dup` does not).
- **No `Math::PI`, no `Math.acos`.** quaternion_rotation.sake:1-4 and shapes_area.sake:1: `def pi =
  3.14159...` and an `acos` via `atan2`; vector_polygon.sake:111 inlines the literal.
- **Updating a field from outside.** stack_vm.sake:146: Ruby `vm.steps += 1` →
  `VM.set_steps(vm, VM.get_steps(vm) + 1)`; there is no compound form for an accessor call.
- **Struct `to_s` as a value.** bitset_permissions.sake:90, physical_quantities.sake:152,
  stack_vm.sake:172, version_constraints.sake:119: Ruby `x.to_s` on a user type is
  `Kernel.to_s(x)` (a type's own `Bits.to_s` would also work, but the Ruby code means "whatever
  `to_s` it has").
- **Abstract stubs.** expr_tree.sake:15-19, shapes_area.sake:4-7, doc_render.sake:2,
  notify_channels.sake:13, stack_vm.sake:21: kept as Ruby's `raise("... not implemented")`; the
  Sake-specific `raise NotImplementedError` (required functions, spec §5.6) would let the checker
  verify every includer, but the Ruby versions do not write it, so I did not add it.

## Ruby comparison

- **Receiver as first parameter, everywhere.** Every method gains a leading parameter (`def +(a, b)`,
  `def to_s(a)`), and every call names its type: `Bits.include_all?(perms[who], Bits.of(need))` for
  `perms[who].include_all?(Bits.of(need))`; `Payable.stub(e, period)` for `e.stub(period)`. This is
  the first thing a Ruby reader sees in every file.
- **Field reads from outside are `T.get_x(v)`.** `Txn.get_amount(t)`, `Vec.get_y(q)`: inside the
  class `@x` reads like Ruby, outside it is the long form (collision_check.sake:25-41 has 20 of them
  where Ruby has `a.cx`).
- **Module dispatch is explicit.** Ruby's duck-typed `shape.area` is `Shape.area(s)` (module) or
  `(Circle|Box|Dot).bounds(s)` (collision_check.sake:71); the set of types is written at the call.
- **No constructor boilerplate.** `attr_reader x, y` replaces Ruby's `initialize` + assignments in
  every class: the Sake versions are shorter there than Ruby's.
- **Tables are functions.** `def rates = once { Hash[...] }` instead of `RATES = {...}`; uses read
  `rates[[from, to]]` instead of `RATES[[from, to]]`.
- **`Array[...]` / `Hash[...]` for growable literals**, and `Array.push(out, x)` for `out << x`.

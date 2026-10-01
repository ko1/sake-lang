# Notes: 13-polymorphism

## shapes_area
- `Shape.area(s)` (dispatch through a mixin) is a static error unless the module itself defines `area`:
  `undefined function `Shape.area`` (hint: `area` is defined in `Circle.area`, `Rect.area`).
  Workaround: an "abstract" stub in the module, `def area(s) = raise("...")`, as Ruby code often does.
- `raise(NotImplementedError, "...")` is rejected (`raise T, message` needs an exception type, got
  `NotImplementedError`): NotImplementedError is not a Sake built-in; used `raise("...")` in both versions.
- Ruby `Math::PI` -> Sake `def pi = 3.141592653589793` (no built-in constants).

## vector_polygon
- Possible interpreter bug: `Array.uniq` does not deduplicate equal Struct values, while `==` and
  `Array.include?` compare them by fields. Repro:
  `P = Struct.new(:x, :y); p(Array.uniq(Array[P.new(1, 2), P.new(1, 2)]))` prints both elements.
  (Ruby's version defines `eql?`/`hash`.) Workaround: a `dedup` helper built on `Array.include?`.
- `!inside` written as `inside == false` (no unary operators).

## money_ledger
- Nothing notable. (Hash with Tuple keys `[from, to]` for the rate table works; Ruby uses a constant
  `RATES`, Sake a function `def rates`.)

## matrix_ops
- Two-index indexing is not available: `m[1, 0]` -> "`m[1, 0]` takes one index"; `def [](m, r, c)`
  cannot be reached. Workaround: index with a Tuple, `m[[r, c]]`, and `r, c = rc` inside `[]`/`[]=`.
- Ruby's swap `rows[a], rows[b] = rows[b], rows[a]` is rejected ("only `a, b = tuple` (local variables, no splat) is supported"); written with a temporary in Sake.

## expr_tree
- A user module can `include Arithmetic` and define `+`/`*`; every node type that includes it gets
  the operators (works, like Ruby).
- `def lift(x) = x in Integer ? Num.new(x) : x` is a Prism syntax error ("unexpected '?'");
  needs `(x in Integer) ? ... : ...` (same in Ruby, which uses `is_a?` instead).
- Struct `==` compares fields recursively, which the simplifier relies on; the Ruby version needs
  an explicit `==` per class.

## polynomial
- No `Array.new(n, 0)`: written `Range.map(0..n - 1) { 0 }`. No `!x`: `zero?(r) == false`.
- `Array.max(Array[a, b])` for Ruby's `[a, b].max`. Ruby's `each_with_index.drop(1).map` (enumerator
  chain) has no Sake form; both versions use `(1...n).map { |i| ... }`.
- Struct `==` on a Poly whose field is an Array works (compares elements, Rational == Integer),
  although the spec says Array equality is undecided.

## fraction_math
- `-g` (unary minus) written `g * -1`; `s.inspect` written `Kernel.inspect(s)`.
- `format("%-7s", frac)` uses the type's own `to_s`, as in Ruby.

## version_constraints
- Ruby's `xs.zip(ys).each { ... break ... }` loop is a `while` with an index in Sake (no `break` in
  blocks).
- `Version.parse("2.1") == Version.parse("2.1.0")` uses Struct field equality in Sake and
  Comparable's `<=>` in Ruby; same result here, but the two can differ in general (Sake's `==`
  ignores a user `<=>`).

## interval_arith
- Nothing notable; the top-level `f(x) = x ** 3 - x * 2 - 5` is used with Integer, Float and Interval.

## life_grid
- A mixin cannot have an abstract stub for a function that yields: with `def each_cell(g) = raise(...)`
  in the module, `each_cell(g) { ... }` is rejected ("CellSet.each_cell does not take a block (it
  has no `yield`)"). Dropping the stub works, since `CellSet.population` itself is defined in the module.
- `g[r, c]` written `g[[r, c]]` (one index only, see matrix_ops); `Array.new(h) { Array.new(w, false) }`
  written with `Range.map`.

## sparse_vector
- Tuples are not comparable: `Array.sort_by(...) { |k, x| [x * -1, k] }` fails at run time
  ("ArgumentError: Array.sort_by: cannot compare elements of types Tuple"). Workaround: a small
  `Ranked` Struct with `include Comparable` and `<=>`, sorted with `Array.sort`.
- No `Hash#dup`: written `Hash.merge(Hash[], h)`.
- `Array.combination(a, 2)` yields Arrays, not Tuples, so `{ |a, b| ... }` gets one argument
  ("block takes 2 parameter(s) but was given 1"); the pairs are built with nested loops instead.
- Ruby constant `STOPWORDS` -> Sake `def stopwords = Set[...]`.

## temperature_units
- Semantic difference: with `include Comparable` and `<=>`, Sake's `==` is still Struct field
  equality, so `20°C == 68°F` was `false` (Ruby: `true`, since Comparable#== uses `<=>`). Fixed by
  defining `def ==(a, b) = (b in Temp) && (a <=> b) == 0` in Sake (accepted and used).
- `-` dispatches on the right operand with `case b in Temp ... in Delta ...` inside `Temp.-`.

## duration_timesheet
- `h, m = text.split(":").map(&:to_i)` fails at run time in Sake ("TypeError: multiple assignment
  needs a Tuple, got Array"); written with `parts[0]`, `parts[1]`.
- `Duration./` returns a Float for a Duration divisor and a Duration for an Integer divisor
  (`case b in Duration ... in Integer ...`).

## notify_channels
- Nothing notable. `retry` inside a `begin/rescue` in a function and `ch in Sms` inside a block work.

## payroll
- `break` is not allowed in blocks: the tax-bracket loop (`BRACKETS.each do |limit, rate| ... break ... end`
  in Ruby) is a `while` with an index and `limit, rate = brackets[i]` in Sake.
- A Struct field `name` has the accessor `get_name`, so the mixin's `name` (used by `stub`) is a
  separate function `def name(e) = @name` in each type, with a raising stub in the module so
  `Payable.name(e)` can dispatch.

## bitset_permissions
- A type can include Bitwise, Arithmetic and Indexable together (`&`, `-`, `[]=` all user-defined).
- No `Integer#to_s(2)`; both versions use `format("%08b", mask)`. Constants `FLAG_NAMES`/`ROLES`
  become functions; `roles` is therefore rebuilt on each call in Sake.
- `[]=` assigns the reader field with `@mask = ...` inside the class (works).

## quaternion_rotation
- No `Math.acos` (and no `Math::PI`): Sake defines `acos(x)` via `Math.atan2(Math.sqrt(1 - x * x), x)`;
  the Ruby version calls `Math.acos`. Output agrees at 3 decimals.
- `-@x` written `0 - @x`, `d = -d` written `d * -1`.

## physical_quantities
- `==` between Tuples is not defined: `@dims == Qty.get_dims(b)` -> "TypeError: Kernel.==: no
  implementation for (Tuple, Tuple)" at run time, even though Tuples work as Hash keys
  (`named_units[dims]`). Workaround: compare the three positions.
- `num, unit = String.split(text, " ")` (Array, not Tuple) needs indexing instead (see duration_timesheet).
- First draft tried to `rescue NoMatchingPatternError`, which is a static error in Sake (program
  errors cannot be rescued); removed.

## stack_vm
- A mixin can supply `to_s` for its includers (`def to_s(ins) = show(ins)` in `Instr`); `puts`,
  interpolation and `format("%s")` use it.
- `String.chomp(l, ":")` does not exist (chomp takes no argument); used `String.delete_suffix` in both.
- `op, arg = l.split(" ")` -> `words[0]`, `words[1]` (Array is not a Tuple).

## collision_check
- Double dispatch: Ruby's `case [a, b] in [Circle, Box] ...` (array patterns) is not available; Sake
  nests `case a in Circle` / `case b in ...`. `bounds`/`moved` are selected with `case s in Circle`
  over the closed set of shape types (no mixin) in Sake, by method dispatch in Ruby.
- Tuple `[name_a, name_b]` works as a Hash key and Set element (`Set.add?`).

## task_heap
- One heap implementation is used with Integer, String and a user Comparable type (`@items[i] < @items[parent]`
  dispatches on the element type).
- Swap through a temporary (no `a[i], a[j] = a[j], a[i]`).

## modint_combinatorics
- Extended Euclid uses temporaries in Sake where Ruby uses `old_r, r = r, old_r - q * r`
  (Sake accepts that form for locals too; nothing failed).

## calendar_dates
- Functions in `class Date` whose first argument is not a Date (`leap?(y)`, `days_in_month(y, m)`,
  `from_ordinal(z)`) are plain namespaced functions, the counterpart of Ruby's `def self.x`.

## color_palette
- Nothing notable.

## doc_render
- `next unless b in Heading` (no parentheses) parses and narrows in Sake.
- The mixin's `word_count`/`height` call the includer's `plain_text`/`render`; `Code` relies on the
  module's default `plain_text`.

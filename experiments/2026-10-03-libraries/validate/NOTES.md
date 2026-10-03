# validate: Result values and record validation in Sake

Files: `lib.sake` (library), `client_signup.sake`, `client_config.sake`, `client_pipeline.sake`,
`client_stress.sake`, `client_schema.sake`, `build.sh` (concatenates and runs each at `--strict`),
`bug_ok_field_union.sake`, `bug_message_explosion.sake` (repros). All five clients run cleanly with
`bin/sake --strict` (level 2) and `--strict=4 -c` except two level-3 `index-nil` reports in
`client_pipeline` (see below).

## API sketch

- **Result** is a Record, `{ok: v}` or `{err: e}` (not a Struct type; see friction 1).
  `module Result` (module_function): `ok(v)`, `err(e)`, `ok?(r)`, `err?(r)`, `unwrap(r)` (raises
  `UnwrapError`), `unwrap_or(r, d)`, `map(r) { |v| }`, `and_then(r) { |v| result }`,
  `map_err(r) { |e| }`, `all(results)` (all values, or *all* errors), `to_s(r)`,
  `attempt { }` (a raised `ValidationError` becomes `{err: message}`).
- **Checker** (`class Checker < {reader: [input, errors]}`), over a `Hash` of String inputs:
  `start(h)`, `required(c, f)` / `optional(c, f)` → String or nil, then
  `length(c, f, s, min, max)`, `matches(c, f, s, re, what)`, `integer(c, f, s, lo, hi)`,
  `one_of(c, f, s, choices)`, `check(c, f, v, msg) { |v| bool }`; each passes nil through and
  returns nil after recording a `FieldError`. `add`, `ok?`, `messages`, `result(c, value)` (→ Result),
  `raise_first(c)` (the exception style: raises `ValidationError` with `field`).
- **Rules as data**: `module Rule` (mixin, `check(rule, v)` → message or nil) included by
  `MinLen`, `MaxLen`, `Pattern`, `IntRange`; `Schema.build`, `Schema.field(s, name, required, rules)`,
  `Schema.validate(s, input)` → Checker.
- Exceptions: `UnwrapError = Exception.new`, `ValidationError = Exception.new(:field)`.

## Friction log

- [language-limit / type-check-false-report] Result as two Struct types,
  `class Ok < {reader: [value]}` / `class Err < {reader: [error]}`, used with `Ok.new([size, at])`,
  `Ok.new([w, h])`, `Ok.new({area:, corner:})` in one program → 9 errors at level 1 already, e.g.
  `String.split: argument 1 must be String, but can be nil | Integer | Array@L213 ...` and
  `multiple assignment: argument 1 must be Tuple|Array, but can be Integer | String | {area: ...`
  → partly (`--types` on the 9-line repro shows `Ok.value: Integer | String`, which explains it;
  the real message did not) → Result as Records `{ok: v}` / `{err: e}` with `case r in {ok:}`,
  since a Record's type is its shape and so keeps a separate type per use → 2 attempts
  (repro `bug_ok_field_union.sake`; this is the documented per-definition field typing, so a
  language limit rather than a bug: there is no generic Struct type).
- [bug / message] the same 9 reports printed **35 MB** of text, single lines of 8.6 MB
  (recursive unions `Array@L213 Array*[... Array@L60[...]]` expanded without limit) → no, the
  terminal was useless; I had to `grep -o '^out[^ ]* error: .\{0,150\}'` to read them → 1 attempt
  to cope. Repro: `bin/sake --strict bug_message_explosion.sake | wc -c` (= 35,034,120). A smaller
  program with the same recursion printed a finite type, so it needs some size to trigger.
- [type-check-false-report] `return nil if ok?(c); e = Array.first(@errors); FieldError.get_message(e)`
  → `FieldError.get_message: argument 1 may be nil (FieldError | nil) [nil]` with
  `hint: reached by the call at line 256 → line 242` → yes → `e = Array.first(@errors); return nil unless e`
  → 1 attempt. Note: the report appeared only when a client first reached `raise_first`; the
  library alone had passed with another client.
- [type-check-false-report] (inherent to nil-returning checkers) the validated record
  `{id: id, qty: qty, sku: sku}` comes out of `Checker.result` as `{ok: ...}` but `qty` is still
  `Integer | nil`, so `price * qty` → `Arithmetic.*: the operands may be nil ([Integer, Integer | nil]) [nil]`
  → yes → `qty || 0` inside the ok branch, a default that can never be used → 1 attempt. The checker
  cannot relate "no errors were recorded" to "no field is nil"; every client that consumes a
  validated record pays this.
- [type-check-false-report] `Array.each(Array.zip(inputs, results)) { |s, r| ... Result.unwrap(r) }`
  → `case/in: argument branch may be nil (Err | nil | Ok) [nil]` (zip pads with nil) → yes, after
  thinking: the arrays have the same length but the checker cannot know → `Array.each_with_index(results)`
  and `inputs[i]` → 1 attempt.
- [type-check-caught-bug] `Hash.each(Hash.sort_by(per_field) { |f, n| -n })` →
  `Hash.each: argument 1 must be Hash, but is Array@L218 Hash.sort_by[[String, Integer]] [type]` →
  yes → `Array.each(...)` → 1 attempt. (Same as Ruby; I just forgot.)
- [type-check-caught-bug] (probe, not in the clients) through the Record Result:
  `Result.unwrap(Result.ok("x")) + 1`, `String.upcase(err)` where err is the messages Array, and
  `Result.map(q) { |n| String.size(n) }` where q holds an Integer were all reported before running,
  with the right types.
- [ruby-habit / message] `errs << "x"` → `Bitwise.<<: the operands are (Array@L1[(none)], String), which the left operand's type does not support [type]`
  → partly (no hint toward `Array.push`) → `Array.push(errs, x)` → 1.
- [ruby-habit / message] `rescue StandardError => e` → `` `StandardError` is not an exception type ``
  → partly (no hint that bare `rescue => e` + `case e in ...` is the catch-all) → `rescue A, B => e` → 1.
- [ruby-habit] `raise ValidationError, "bad"` (type with a field) →
  `V has fields besides message; raise it with `raise V.new(...)`` → yes → `raise ValidationError.new(msg, field)` → 1.
- [language-limit / message] storing rules as lambdas, `Array[->(s) { String.size(s) > 2 }]` →
  `unsupported syntax: lambda` → partly (no pointer to the alternative) → a mixin `Rule` with one
  Struct type per rule kind and dispatch through `Rule.check(rule, v)` → 1, and ~35 lines of lib.
- [message] `Rule[MinLen.new(3)]` (an Array of things that include Rule) →
  ``undefined function `Rule.new[]` `` with a hint listing `Integer.new[]`, `Float.new[]`,
  `RuntimeError.new[]`, ... → no (`Rule.new[]` is not what I wrote; it should say a module is not
  a type and suggest `Array[...]`) → `Array[MinLen.new(3), ...]` → 1. The dispatch check still
  caught a wrong element at the use: pushing `42` gave
  `Rule.check dispatches on its first argument, which can be Integer; the types that include Rule are MinLen, MaxLen, Pattern, IntRange`.
- [tooling] one-file programs: every report is in `out/X.sake` line numbers; client lines are offset
  by the library's length (239), so I added that offset to `build.sh`'s header. No name clashes
  happened, but `ValidationError`/`UnwrapError` defined in the lib must be unique program-wide, and
  a lib function with a bug stays silent until some client reaches it (`--types` lists them as
  `dead functions`).
- [type-check-false-report?] level 3 (`--strict=3`, not the recommended level):
  `size, at = String.split(s, "@")` then `String.split(size, "x")` → `index-nil` → yes. Actually
  correct: `String.split("", "@")` is `[]`, so `size` can be nil. Left as is at level 2.

## What felt good

- **Records as a generic Result.** Once I switched to `{ok: v}` / `{err: e}`, `case r in {ok:}`
  both tests the variant and binds the payload, and each `{ok: T}` keeps its own T. `map`,
  `and_then`, `map_err` with `yield` read exactly like Ruby, and a 200-step `and_then` chain, a
  Result inside a Result, and `Result.all` all checked at level 2 with no annotations.
- **Mistakes found through the Result**: unwrapping an ok String and adding 1, or treating the
  error Array as a String, were reported before running with exact types.
- **Best moment:** `client_schema` ran cleanly at `--strict` on the first try: a heterogeneous
  `Array[MinLen, MaxLen, Pattern]` stored in a Hash, `Rule.check` dispatching per element, and a
  `case rule in MinLen ... in IntRange` with no `else` that the checker knows is complete.
- **Exception flow**: level 4 followed `UnwrapError` through `Result.unwrap` into the client's
  `begin/rescue` and did not complain; `ValidationError` raised in the library and rescued by name in
  `client_config` was clean too. Typed exceptions with a field (`ValidationError.get_field(e)`) are
  nicer than parsing messages.
- `class FieldError < {reader: [field, message]}` and `FieldError[]` for the error list: the field
  types showed up exactly in `--types` (`Checker.errors: FieldError[]@L91`), and `reader:` kept the
  Checker's error list from being replaced from outside. It never got in the way.

## What felt bad (top 3)

1. **No generic Struct type.** The natural Ruby-ish `Ok`/`Err` classes fail at level 1 as soon as
   two different payload types exist in one program. Cost: ~20 min and a rewrite of the Result
   half of the lib and all clients (≈60 lines touched); the fix (Records) is good but not obvious
   from the docs, which present Records as plain data.
2. **The 35 MB error output.** It hid a 9-error report behind a type printer that never truncates.
   Cost: ~10 min to filter it and build the repro.
3. **nil does not carry "validated".** The checker style (`nil` after recording an error) is the
   simplest Sake design, but the validated record still has `T | nil` fields, so every consumer
   writes a dead `|| 0` or a re-check. Exceptions (raise on first problem) avoid this but lose
   "report every problem". Cost: small per use (one line), but it is in every client.

## Library design under Sake

- **In Ruby** I would write `Result` as `Ok = Struct.new(:value)` / `Err = Struct.new(:error)` with
  methods `r.map { }`, `r.and_then { }`, or just exceptions with a `ValidationError < StandardError`
  hierarchy and `errors.add(:field, msg)`. In Sake: Result is a Record shape plus a module of
  functions (`Result.map(r) { }`), since a Struct type would share one field type across all uses.
- **No stored blocks** → validation rules cannot be lambdas. Instead each rule kind is a Struct type
  including the `Rule` mixin, which turned out well: rules are printable, inspectable data
  (`client_schema` lists them). The imperative `Checker.*` API with `yield` for a one-off custom
  rule covers what a lambda would be used for at the call site.
- **No exception hierarchy** → no "rescue any validation problem" base class; a client lists the
  types (`rescue ConfigSyntaxError ... rescue ValidationError`). With two or three types that was
  fine, and it made the set of failures explicit.
- **No optional/keyword args** → `Checker.integer(c, field, s, lo, hi)` has every bound positional;
  in Ruby it would be `integer(:age, in: 13..130)`. Passing a Range was possible but I kept two ints.
- **Exceptions vs Result**: both are comfortable. The exception version of the pipeline
  (`parse_box_raise`) is shorter (8 vs 13 lines) and flat, while the `and_then` version nests one
  level per step because the block cannot be stored or composed. Exceptions fit "stop at first
  problem"; Result + Checker fit "report every problem". `Result.attempt { }` bridges the two.

## Numbers

- Lines: `lib.sake` 239; clients 30 (signup) + 88 (config) + 86 (pipeline) + 66 (stress) +
  36 (schema) = 306.
- Static errors before each program ran clean (level 2):
  - signup: 0.
  - config: 1 (false report: `Array.first` after an emptiness check).
  - pipeline: 9 with the Struct Result (all false reports from shared field types; 1 of them the
    `Array.zip` nil padding), then 0 after the Record rewrite.
  - stress: 2 (1 my mistake `Hash.each` on an Array; 1 false report, nil in a validated record).
  - schema: 0.
  - Probes outside the clients: 4 Ruby-habit errors (`<<`, lambda, `StandardError`, `raise T, msg`),
    1 message problem (`Rule[...]`), 3 caught bugs.
- Level-2 reports I could not remove: none. Level 3: 2 `index-nil` reports in `client_pipeline`
  (genuine: empty input), left. Level 4: clean.

## Suggestions

1. **Bound the type printer** (friction: 35 MB output): cut a type after N characters or depth
   (`... (12 more)`) and print the full one only with a flag. This is the one that blocked me.
2. **Say why a Struct field is a union** (friction: Ok/Err): when a value read from a field has
   several types, add a hint like `Ok.value holds Integer | String across the program (stored at
   lines 8, 9); a Record {value: ...} keeps a type per use`. Better still, document "a Record
   is the generic container" in the tutorial's section 9.
3. **Hints for missing Ruby forms** (friction: `<<`, lambda, StandardError, `Rule[...]`):
   `Array << x` → `hint: Array.push(a, x)`; lambda → `hint: pass a block to a function with yield,
   or store a Struct value and dispatch through a mixin`; `StandardError` → `hint: rescue => e`;
   `Module[...]` → "Rule is a module, not a type; use Array[...]".
4. **Narrow on emptiness** (friction: `Array.first` after `ok?`): treat `return if Array.empty?(a)`
   (or a function that returns it) as making `Array.first(a)` non-nil, as `if x` does for locals.
5. **A way for a checked record to drop nil** (friction: `qty || 0`): e.g. a pattern that narrows
   while binding (`ok => {qty: Integer => qty}`, raising if not), so a validated record can be
   taken apart once without a dead default.

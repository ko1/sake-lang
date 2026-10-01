# Notes (14-errors)

## General

- Messages of built-in exceptions carry a Sake prefix naming the operation, e.g.
  `Exception.message(e)` after `Integer("abc")` is `Kernel.Integer: invalid value for Integer(): "abc"`
  (Ruby: `invalid value for Integer(): "abc"`), `Hash.fetch: key not found: "zz"`,
  `Arithmetic./: divided by 0`. Programs here never print built-in messages; they print their own text.
- No `break` in blocks: Ruby's `break if done` inside `each` became `next if done`. No unary
  minus: `sort_by { -x }` is written `sort_by { 0 - x }`.
- `puts(e)` of an exception value prints `#<ValidationError: m field="f">` (Ruby prints the message).

## registration_form

- Tuples are not comparable, so Ruby's `sort_by { |f, n| [-n, f] }` fails:
  `ArgumentError: Array.sort_by: cannot compare elements of types Integer` (the message names
  Integer although the keys are Tuples). Repro: `p(Array.sort_by(Array[3, 1, 2]) { |x| [x, "a"] })`.
  `Array.sort(Array[[2, "b"], [1, "a"]])` says `cannot compare elements of types Tuple`.
  Workaround: a String key `format("%06d %s", 999999 - n, f)`.

## retry_backoff

- A user function named `call` cannot be called: `Service.call(svc, x)` is rejected with
  `error: type scope `Service.(...)` is not supported yet` (Prism gives `.()` and `.call()` the same
  name). Renamed to `request` in both versions.

## csv_import

- Ruby uses `Integer(raw, exception: false)`; Sake has no keyword arguments, so `Integer(raw) rescue nil`.

## expr_calculator

- Guards in `in` branches are not supported: `in :op if Token.get_text(t) == "("` gives
  `error: unsupported pattern `:op if ...`; use a type (...)`. Moved the test into the `else` branch.
- The AST is 3-element Tuples (`[:add, l, r]`, `[:num, 5, col]`) taken apart with `kind, a, b = node`
  (no array patterns). Ruby's `env.fetch(a) { raise ... }` became `env[a]` plus a nil check.

## result_pipeline

- No way to extend a Record (Ruby's `order.merge(subtotal: ...)`): each step rebuilds the Record
  with all fields. Ruby's nested pattern `in {ok: {customer:, ...}}` became `in {ok:}` followed by
  `ok => {customer:, ...}` (only flat `{x:, y: name}` patterns exist).

## card_validation

- Ruby compares `[year, month] <=> today`; Tuples have no ordering in Sake, so the comparison is
  spelled out (`year < now_y || (year == now_y && month < now_m)`).

## matrix_checks

- `==`/`!=` between Tuples is not defined (documented): `p([2, 3] != [2, 3])` gives
  `TypeError: Kernel.!=: no implementation for (Tuple, Tuple)`. Ruby's `shape == other.shape`
  became a helper comparing both positions.

## unit_quantities

- `kind = e in QuantityFormatError ? "format" : "unit"` is a syntax error (also in Ruby); it needs
  parentheses: `(e in QuantityFormatError) ? ...`. Ruby uses `e.is_a?(...)`.

## job_queue

- Same Tuple-key limitation in `Array.min_by(due) { |j| [run_at, id] }`; the message is
  `ArgumentError: Array.min_by: cannot compare elements of types Job` (it names the element type,
  not the key type). Workaround: `format("%06d %s", run_at, id)` as key.

## password_policy

- `Array.last` takes no count (`Array.last(a, 3)`: `wrong number of arguments for Array.last
  (given 2, expected 1)`); Ruby's `history.last(3)` became `Array.take(Array.reverse(h), 3)`.

## error_wrapping

- Sake has no automatic `Exception#cause`; the Sake version carries an explicit `cause` field
  (holding nil, a DecodeError, a StorageError, or the built-in ArgumentError/KeyError value) and
  walks it with `case ... in`. The Ruby version uses Ruby's built-in `cause`.

## spreadsheet_errors

- String Ranges cannot be iterated: `Range.to_a("A".."C")` gives `TypeError: Range.to_a: this
  operation needs a Range that starts with an Integer, got "A".."A"`. Workaround:
  `Array.map(Range.to_a(String.ord(a)..String.ord(b))) { Integer.chr(it) }`.
- Same `v in Float ? a : b` precedence issue as unit_quantities (needs parentheses).

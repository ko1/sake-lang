# Review: 14-errors (2026-10-05)

All 25 programs run with `bin/sake --strict=0` and match their `.out` (exit 0). Note: the `.rb`
files in this directory are symlinks to `../../corpus/14-errors/`, which does not exist relative to
`corpus-v3/`; the Ruby versions were read from `experiments/2026-10-01-inference-500/corpus/14-errors/`.

In every program the exception types `E = Exception.new(:f, ...)` became `class E < StandardError`
+ `attr_reader f, ...` (the Ruby versions all subclass StandardError). That is not repeated below.

- bank_transfers: exception classes; `|(from, to, amount), i|` block destructuring instead of `req` + multiple assignment.
- card_validation: exception class; `brands` table in `once`; per-entry `begin/rescue` became a block-level `rescue` (`do ... rescue CardError => e ... end`), as Ruby.
- circuit_breaker: exception classes; `rescue RemoteError` without an unused `=> e`.
- config_loader: exception classes; `schema` in `once`; block-level `rescue` in `load`, which also lets `kind, section, key, value = parse_line(...)` assign `section` directly (no `sec` temp); `Integer.between?`/`Float.between?` for range checks; `Hash.each_key(schema)`; `unless rule` instead of `if rule == nil`.
- contracts: exception class; `|_, status, _|` for the unused block params.
- csv_import: `categories` in `once`; `y, mo, d = Array.map(MatchData.captures(m)) { String.to_i(it) }`; `Range.cover?(1..12, mo)` and `Integer.between?(d, 1, ...)` as in Ruby.
- dependency_resolver: exception classes; `Package` Struct -> `class` + `attr_reader`; `registry` builds the Hash with `Array.map {...}` + `Array.to_h` instead of a store loop; block-level `rescue` in the main loop.
- error_wrapping: exception classes, `DecodeError`'s `cause = nil` default so the non-wrapping raises drop the trailing `nil` argument; `storage` in `once`; main loop over `Range.each(1..7)` with block-level `rescue`; `first, *rest = chain(e)` as Ruby.
- expr_calculator: exception classes; `Token` Struct -> `class` + `attr_reader`; block-level `rescue` in the main loop.
- http_error_mapping: exception classes; `Request`/`Response` Structs -> `class` + `attr_reader`; `users`/`tokens` in `once`; `bad = Hash.keys(body) - Array["name", "role"]` (Array difference, as Ruby) instead of a `select`; `if name && ...`; block-level `ensure` in the main loop.
- job_queue: exception classes; `|(kind, payload), i|`; `Array.sum(done + dead) { ... }` instead of `sum(map(concat(dup ...)))`.
- ledger_reconcile: exception classes; `Txn` Struct -> `class` + `attr_reader`; `_` for unused block params; `Array.sum(xs) { ... }` with a block.
- log_triage: exception classes; `Entry` Struct -> `class` + `attr_reader`; `levels` in `once`; `attrs = Array.to_h(String.scan(...))` as Ruby; block-level `rescue` in `parse_all`.
- matrix_checks: exception classes; `Range.sum(0...k) { ... }` and `Array.sum(rows) { Array.sum(it) }`; block-level `rescue` in the totals loop; `rescue IndexError` without `=> e`.
- nested_schema: `Rule` Struct -> `class` + `attr_reader`; unexpected fields by `Hash.keys(value) - Hash.keys(fields)` as Ruby; `|w, _|`.
- order_lifecycle: exception classes; `transitions` in `once`; `unless target`; block-level `rescue` in `run`; `Hash.map(final_states)`.
- param_coercion: exception class; `search_spec`/`sort_options` in `once`; unknown parameters by `Hash.keys(raw) - Array.map(search_spec) { |name, *| name }` (Ruby's `keys - SPEC.map(&:first)`); `if lo && hi && lo > hi`.
- password_policy: exception class; `User` Struct -> `class` + `attr_reader`; `dictionary` in `once`; block-level `rescue` in the main loop; `|k, _|`.
- quote_fallback: exception classes; `Provider` (`attr_reader` + `attr_accessor down`) and `Clock` (`attr_accessor now`) as classes; block-level `rescue` in `quote_with_fallback` (with `return` from inside the block); `rescue ProviderDown, KeyError` without `=> e`.
- registration_form: `Submission`/`FieldError` Structs -> `class` + `attr_reader`; `allowed_countries`/`reserved_names` in `once`.
- result_pipeline: `catalog`/`coupons`/`credit` in `once`; Record literals use the `{customer:, sku:}` shorthand, as Ruby; `Hash.map(reasons)`.
- retry_backoff: exception classes (GiveUpError now `< StandardError`, as Ruby); `step = @script[@calls] || "ok"` as Ruby; `Hash.map(stats)`.
- spreadsheet_errors: exception class; `Sheet` Struct -> `class` + `attr_reader`; rescue gives `CellError.get_code(e)` directly (not `"#{...}"`); `cell_value` ends with `cache[ref] = value`; error cells via `Hash.select` + `Hash.sort_by`, as Ruby.
- unit_quantities: exception classes; `Quantity` Struct -> `class` + `attr_reader`; `units`/`aliases` in `once`; block-level `rescue` in the main loop; `rescue ArgumentError` without `=> e`; `Array.sum(lengths) { ... }`.
- warehouse_reservation: exception classes; `Array.sum(warehouses) { ... }`; `break if remaining == 0` (Ruby's form) instead of `next`.

Unchanged: none (every program had `Exception.new` exception types).

## Friction

- **No implicit `cause`.** error_wrapping.sake:7,11 — Ruby's `raise ProfileError.new(...)` inside a
  `rescue` sets `e.cause` automatically, and `chain` (Ruby) walks `current.cause` uniformly. Sake has
  no `cause`, so the wrapper types carry an explicit `cause` field, every wrap passes `e`, and
  `chain` (error_wrapping.sake:57-79) needs one `case` arm per type to read it, plus explicit
  `current = nil` arms (lines 70, 73, 76) for the built-in leaves. Ruby's `else current.class.name`
  cannot be written (no class name of a value).
- **No exception hierarchy.** bank_transfers.sake `rescue InsufficientFunds, AccountNotFound,
  AccountFrozen, LimitExceeded, ArgumentError => e` and every `rescue` list must name each type;
  Ruby could have had a common base. Not a problem in this corpus (the Ruby versions also list
  them), but `class E < StandardError` reads like inheritance and is not.
- **Nested Record patterns.** result_pipeline.sake:81-83 — Ruby matches
  `in {ok: {customer:, sku:, qty:, total:}}` in one pattern; Sake rejects a nested pattern ("only
  Record patterns that bind fields"), so it is `in {ok:}` then `ok => {customer:, ...}`.
- **No Record update.** result_pipeline.sake:30 — Ruby's `order.merge(subtotal: ...)`; Sake rebuilds
  the Record field by field (`{customer:, sku:, qty:, coupon:, subtotal: ...}`), now shorter with
  the `k:` shorthand.
- **`Array.to_h` takes no block.** dependency_resolver.sake:20-34 — Ruby `[...].to_h { |pkg| [pkg.name, pkg] }`;
  Sake `Array.map {...}` then `Array.to_h(_)`. error_wrapping.sake:31-36 and
  param_coercion `parse_query` keep a store loop for the same reason.
- **`Array.last(a, n)` is missing.** password_policy.sake:40 — Ruby `history.last(3)`; Sake
  `Array.take(Array.reverse(h), 3)` (only Range's `first`/`last` take n).
- **String ranges do not iterate.** spreadsheet_errors.sake:56 — Ruby `(m[1]..m[3]).flat_map`; Sake
  goes through `String.ord`/`Integer.chr` because Range iteration needs an Integer start.
- **`case` without `else` raises.** dependency_resolver.sake:48 (`in nil then nil`) and
  order_lifecycle.sake:38 (`else nil`): Ruby's `case/when` falls through silently; Sake needs an
  explicit empty branch.
- **Mixin functions need the subject passed.** contracts.sake:7,29 — Ruby's `require!(cond, what)`
  uses `self`; Sake writes `require!(s, cond, what)` and the module's functions take `x` first.
- **Accessor writes from outside.** quote_fallback.sake:24 — Ruby `clock.now += latency`; Sake
  `Clock.set_now(clock, Clock.get_now(clock) + ...)`; `@now +=` only works inside the class.
- **No `loop do`.** expr_calculator.sake:67,77 use `while true`.
- **`Integer(x, exception: false)`** is not available; csv_import.sake:30 and result_pipeline.sake:20
  use `Integer(raw) rescue nil` (also valid Ruby, so minor).

## Ruby comparison

- Every field read is `Type.get_f(x)` and every exception field is `E.get_f(e)` /
  `Exception.message(e)` instead of `e.f` / `e.message`: the most visible difference, and the bulk
  of each program's length (e.g. warehouse_reservation.sake rescue clauses).
- Exception classes are now two lines (`class E < StandardError` / `attr_reader ...`) instead of
  Ruby's 8-line `initialize` with `super(message)`; `message` is the implicit first field of `new`.
- Tables that Ruby holds in constants are `def name = once { ... }` and called as `name`.
- Instance methods take the instance as an explicit first parameter (`def withdraw(a, amount)`,
  bank_transfers.sake:21) and are called `Account.withdraw(src, amount)` (line 51).
- Block-level `rescue`/`ensure` (`do |x| ... rescue E => e ... end`) now works as in Ruby, so the
  loops look like the Ruby ones; per-iteration `begin` remains only where Ruby also has one.
- Collections are spelled `Array[...]`/`Hash[...]`, with `[a, b]` being a fixed Tuple.

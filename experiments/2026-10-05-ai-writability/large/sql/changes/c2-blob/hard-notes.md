# c2-blob: notes on change-hard.md

change.md: 187 lines. change-hard.md: 141 lines.

## Hidden tests (tasks/sql-change-hidden/c2-blob/7/, 55 tests)

Each of the 55 tests was read and its `.out` checked against spec 1-6 + change-hard.md. All follow;
no rule had to be added after the check. Points that needed more than one rule to derive:

- 007, 016, 017 (`n < b`, `s IN (X'45')`, `'A1' IN (SELECT h FROM allowed)`): 7.3 (affinity never
  converts a BLOB; a BLOB-typed expression has no affinity) + 1.9 / 2.3 / 4.3 affinity rules.
- 021 (`nullif(X'31', 1)` = `X'31'`): 1.11 nullif "compared without affinity" + 7.2 equality.
- 029 (`n INTEGER DEFAULT X'3132'`, `b BLOB DEFAULT -1`): 7.4 Defaults (reported when the row needs
  it) + storage rules (`INT` for an INTEGER).
- 030, 055 (`ADD COLUMN ... BLOB DEFAULT X'..'` on a table with rows): 5.6 (existing rows get the
  default converted as by 1.5) + 7.4 (BLOB into BLOB column stored unchanged).
- 034 (`lead(v, 1, X'EE')`, `nth_value`, `max(v) OVER`): 7.1 "a BLOB passes through" + 7.2 order.
- 035, 036, 040 (`X'2033' + 0` = 3, `X'3278'` true, `CAST(X'323565' AS INTEGER)` = 25): 7.5 / 7.6
  "as the TEXT that is its text form" + 1.8 numeric prefix / 2.3 CAST.
- 037 (`sum` over 2 and `X'33'` = `5.0`): 7.3 numeric-literal test never applies, + 3.2 sums.
- 044, 045 (`hex(1e20)`, `hex(NULL)` = `''`, `length(hex(NULL))` = 0, arg-count error): 7.6 hex +
  1.3 text form of REAL.
- 050, 053 (`X'31' || X'32'` is TEXT, so `= X'3132'` is 0 and storing `body || X'21'` into a BLOB
  column fails with TEXT): 7.1 "result is TEXT, even when every input is a BLOB" + 7.4.
- 052 (BLOB separator of group_concat): 3.2 "sep's text form" + 7.1 text form.

## Sites of the original's "Where it applies" and the general rule each follows from

| site | rule in change-hard.md |
|---|---|
| literal | 7.1 literal grammar, malformed literal, printed form |
| typeof | 7.1 `typeof` |
| compare | 7.2 order/equality used by every comparison; 7.3 affinity never converts a BLOB |
| order-by | 7.2 "every sort (ascending or descending; NULL placement unchanged)" |
| distinct | 7.2 "every test of two values for equality" (BLOB vs TEXT always different) |
| compound | 7.2 same as distinct |
| in | 7.2 equality + 7.3 affinity (applies to "every rule that applies it", incl. 2.3's list conversion) |
| case | 7.2 equality + 7.3 affinity (CASE x WHEN uses `=` with affinity, 2.3) |
| coalesce | 7.1 "a BLOB passes through" (coalesce/ifnull); 7.2 equality (nullif) |
| store | 7.4 storage rules and `INT` message |
| unique | 7.2 equality (2.1 UNIQUE uses "equal as in 1.9"), 7.4 storage; NOT NULL unchanged |
| default | 7.4 Defaults; 7.1 grammar `default-value` |
| min-max | 7.2 "every choice of a smallest or largest value"; count unchanged (BLOB is non-NULL) |
| window | 7.2 equality/order (PARTITION BY, window ORDER BY); 7.1 "a BLOB passes through" (lag, lead, first/last/nth_value) |
| numbers | 7.5 numeric prefix wherever TEXT is read as a number (arithmetic, truth values, abs, round); 7.3 sums |
| cast-to-blob | 7.6 CAST to BLOB |
| cast-from-blob | 7.6 CAST from a BLOB |
| length | 7.6 exception table: length |
| hex | 7.6 hex |
| substr | 7.6 exception table: substr |
| instr | 7.6 exception table: instr |
| text-functions | 7.1 text form rule (`||`, upper, lower, trim, replace, group_concat give TEXT) |

## Things that could not be stated without naming a site

- The three byte-level exceptions (`length`, `substr`, `instr`) and the new function `hex` are
  per-function rules, so they are named.
- The sum rule (a BLOB is always a non-INTEGER in `sum`/`total`/`avg`) is stated through the 1.5
  step 2 numeric-literal test, but still names 3.2's sums, since that is the one rule where TEXT and
  BLOB differ when read as numbers.
- `CAST` and the `default-value` / `type` grammar are new syntax and are named.

# Reference implementation, change c2-blob: where the tests and the specification disagree

Implementation: `large/sql/changes/c2-blob/ref/` (a copy of `large/sql/ref/`, Ruby 4.0.2). Probes ran
on SQLite 3.46.1 (python3 `sqlite3`, and `harness/sql_oracle.py`, which adds STRICT).
Result: stages 1-6 public 366/366, hidden 369/369; c2-blob public 8/8, hidden 55/55.

The change: a BLOB is `Values::Blob` (a struct over a frozen binary String, so equality and hashing are
by bytes). `Values.display` prints (`X'..'`), `Values.to_text` is the text form; `compare` ranks BLOB
above TEXT and compares bytes; `to_number` reads a BLOB's text form. The lexer reads `X'..'`; the parser
takes BLOB as a type, a default and a literal. `Table#convert` adds the BLOB column and rejection rules
(`INT` / `REAL` / `TEXT` / `BLOB`), and a BLOB INTEGER PRIMARY KEY is `datatype mismatch`. A BLOB column
and `CAST(.. AS BLOB)` have no affinity. `length`, `substr`, `instr` work on bytes for BLOBs; `hex` is
new; `sum`/`total`/`avg` take a BLOB as non-INTEGER.

## A. Tests that disagree with the specification

None. Every public and hidden c2-blob test agrees with change.md as written, and every example in
change.md 7.1-7.10 gives the same result in SQLite (probed one by one).

## B. A defect of the stage 1-6 reference that the change exposes

1. **CAST of TEXT to INTEGER skipped only spaces** (`large/sql/ref/values.rb`, `INTEGER_PREFIX = /\A *.../`).
   2.3 says "after leading whitespace", and 1.1 defines whitespace as space, tab, newline, carriage
   return. `CAST(char(9) || '12' AS INTEGER)` is 12 in SQLite and by 2.3; the old reference gave 0. No
   stage 1-6 test has a tab or newline before a CAST to INTEGER, so it went unnoticed. 7.9 makes it
   reachable through BLOBs too (`CAST(X'09313209' AS INTEGER)`: spec and SQLite 12). Fixed in the
   copy (the regex now skips `[ \t\n\r]`); all stage 1-6 tests still pass. Not a test or spec problem.

## C. Rules that are unclear, ambiguous or missing

1. **LIKE (and GLOB) with a BLOB operand.** 7.1 says that wherever a value is turned into text the
   BLOB's text form is used, which would make `X'41' LIKE 'A'` 1. SQLite gives 0 for that, for
   `'A' LIKE X'41'` and even for `X'41' LIKE X'41'`. change.md avoids the case ("does not occur in
   tests"), which is right, but the text-form rule as worded covers LIKE. Better to say
   in 7.1 or 7.10 that LIKE with a BLOB is left undefined (or say what it gives).
2. **Text form of non-printable bytes.** 7.1 limits tests to printable ASCII, but `length`, `upper`
   and `||` of a BLOB with other bytes are left undefined. This is acceptable because the tests respect
   the limit. Worth saying outright that the result is undefined there.
3. **BLOB as a numeric *argument*** (`substr(x, X'32')`, `round(x, X'31')`, `ntile(X'32')`,
   `lead(v, X'31')`). 7.8 lists arithmetic, truth, `abs` and `round`'s first argument, but not argument
   positions that 2.4 / 6.x read as numbers. SQLite reads them by numeric prefix (`substr('hello',
   X'32', X'33')` = `ell`, `ntile(X'32')` works), and the reference does the same. No test uses it.
4. **RANGE frames with a BLOB ORDER BY key** (6.x offsets). This is unspecified. SQLite treats BLOB keys
   like TEXT ones (each row's frame is just its peers); the reference does the same. No test uses it.
5. **The statement splitter rule** ("a blob literal is skipped when looking for `;`") follows from
   the string-literal rule already in 1.2, because the quote that starts the literal is what is
   skipped. Any `;` between the quotes also makes the literal malformed, so the rule can only change
   *which* text becomes the `syntax error`. Not wrong, but no test can tell it apart.

## D. "Where it applies" sites the hidden tests do not really test

1. **numbers: `round`.** No public or hidden test calls `round` on a BLOB. It cannot be generated as
   things stand: `harness/sql_oracle.py` replaces `round` with `spec_round`, whose `text_to_number`
   applies a `str` regex to `bytes` and fails, so the oracle rejects any test with `round(BLOB)`.
   SQLite's own `round(X'3132')` is 12.0, as 7.8 says. To cover it, `spec_round` must decode `bytes`
   first.
2. **store: a BLOB into an INTEGER PRIMARY KEY (`datatype mismatch`).** Only the public test
   `006-store-blob-elsewhere` covers it. No hidden test stores a BLOB into an INTEGER PRIMARY KEY.
3. **window: `last_value`, and `min` over a frame.** Only `lag`, `lead`, `first_value`, `nth_value`
   and `max` are exercised (hidden 034). Minor: they share code with the tested ones in the reference.

Every other site has at least one hidden test that would fail if the site were not changed. I checked
this site by site: literal 001-003, typeof 004-005, compare 006-008, order-by 009-011, distinct 012-013,
compound 014-015, in 016-017, case 018-019, coalesce 020-021, store 022-024, unique 025-027,
default 028-030, min-max 031-032, window 033-034, numbers 035-037 (arithmetic, unary minus, truth, abs,
sum/total/avg), cast-to-blob 038-039, cast-from-blob 040-041, length 042-043, hex 044-045, substr
046-047, instr 048-049, text-functions 050-052.

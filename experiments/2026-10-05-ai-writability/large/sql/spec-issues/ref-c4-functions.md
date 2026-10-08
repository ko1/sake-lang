# Spec issues found by the reference implementation: c4-functions

Implementation: `large/sql/changes/c4-functions/ref/functions.rb` (+22 lines; no other file changed).
Results: stages 1-6 public 366/366, hidden 369/369; change public 7/8, change hidden 16/17.
Both failures are the same test defect (issue 1); with `first`/`last` renamed (`fname`/`lname`) in a
scratch copy, both tests pass with the expected outputs unchanged.

## 1. Tests use the keywords FIRST and LAST as column names (tests wrong)

- Tests: public `7/003-concat-table` (`CREATE TABLE people (id INTEGER, first TEXT, last TEXT, age INTEGER)`)
  and hidden `7/017-mixed-update-join` (`CREATE TABLE users (id INTEGER PRIMARY KEY, first TEXT, last TEXT, ...)`).
- Expected (SQLite, where FIRST/LAST are non-reserved): `1|Ada.Lovelace`, ... and `1|mia.ng`, ...
- Specified: 1.2 lists `FIRST` and `LAST` as keywords, says an identifier is "not a keyword", and that
  "tests do not use keywords ... as table, column or alias names". So the CREATE TABLE is a syntax
  error and every later statement fails (`Error: syntax error` / `no such table`).
- Judgement: the tests are wrong. Rename the columns (e.g. `fname`, `lname`). The program was not
  changed to accept keywords as names.

## 2. "Where it applies" sites not really tested by the hidden tests

change.md's intro lists the places the functions may appear. The hidden tests cover result columns,
WHERE, ORDER BY, GROUP BY, HAVING, SET, subqueries, aggregate arguments (`group_concat(concat(...))`,
`count(concat_ws(...))`), a view and INSERT ... SELECT. Not covered:
- `VALUES` (no new function inside an `INSERT ... VALUES` row);
- `ON` (the join in 017 has `ON k.uid = u.id`; the new functions are only in the select list);
- window calls' arguments and window-specs (016 wraps `lag(...) OVER` inside `sign`, and uses
  `concat_ws(..., rank() OVER ...)`; no new function appears in an `OVER (PARTITION BY / ORDER BY ...)`
  or as a window function's argument).
These are not per-function bullets of "Where it applies", so each bullet (concat, concat_ws, char,
unicode, sign) is itself tested; only the generic site list is partly untested.

## 3. Minor unclear or untested points (no disagreement)

- `sign` on TEXT: "removing leading and trailing whitespace" refers to 1.5 step 2 (space, tab, newline,
  carriage return); tests only use spaces. SQLite agrees for tab/newline (`sign(char(9)||'5'||char(10))` = 1).
- `sign` on TEXT whose literal overflows (`'1e999'`, a 20-digit integer) is unspecified; tests do not use it.
- `char` outside 32..126, with NULL, REAL or TEXT is explicitly out of scope; fine as written.

# Reference implementation, stage 1: where the tests and the specification disagree

Implementation: `large/sql/ref/` (Ruby). SQLite 3.46.1 (python3 `sqlite3`) used for the probes below.
Result: public 74/76, hidden 75/77. The four failures are the cases in section A; the program follows
the specification there, not the test.

## A. Tests whose expected output contradicts the specification

1. **`tests/1/029-order-by-alias` uses the keyword `KEY` as an alias.**
   Statement: `SELECT c, b AS key FROM t ORDER BY key;`
   Expected (test): `q|10`, `r|20`, `p|30`. Specified: `Error: syntax error`.
   Spec 1.2: `KEY` is in the keyword list, an identifier is "not a keyword", and "tests do not use
   keywords ... nor other words that are keywords in SQLite (such as `key`, ...)". SQLite accepts `key`
   as a fallback identifier, so the oracle printed rows.
   Judgement: **the test is wrong** (it breaks the spec's own promise). Rename the alias (e.g. `k`).

2. **`tests/1/067-scenario-contacts` uses the keywords `FIRST` and `LAST` as column names.**
   Statement: `CREATE TABLE contacts (id INTEGER, first TEXT, last TEXT, phone TEXT, age INTEGER);`
   Expected: the table is created (first line of output `Error: cannot store TEXT value in INTEGER
   column contacts.age`, from a later INSERT). Specified: `Error: syntax error` for the CREATE and for
   every later statement that names `first`/`last`; the rest of the script then diverges.
   Spec 1.2 (keyword list has `FIRST`, `LAST`). Judgement: **the test is wrong**; rename the columns.

3. **`tasks/sql-hidden/1/069-scenario-hotel` uses the keyword `VIEW` as a column name.**
   Statement: `CREATE TABLE room (no INTEGER, floor INTEGER, beds INTEGER, rate REAL, view TEXT);`
   Expected: the table is created. Specified: `Error: syntax error` (and `no such table: room` after).
   Spec 1.2 (keyword list has `VIEW`). Judgement: **the test is wrong**; rename the column.
   (Cases 1-3 suggest the test generator does not check names against the spec's keyword list; a
   check in `sql_oracle.py` would catch them.)

4. **`tasks/sql-hidden/1/005-comments-everywhere`: a statement is dropped by the oracle.**
   Statement: `/* block with -- inside */ SELECT 5;`
   Expected: no output line. Specified: `5` (spec 1.2: `/* ... */` is a comment, so `--` inside it
   is not). SQLite itself prints 5 for this statement.
   Cause: `harness/sql_oracle.py` `strip_comments` removes `--...` comments before `/* */` ones, so
   the statement looks empty and `run` skips it without executing it.
   Judgement: **the test (oracle) is wrong**. Fix `strip_comments` to scan left to right (as
   `split_statements` does) and regenerate the `.out`.

## B. Rules that are unclear or missing (the tests do not decide them; SQLite's behaviour noted)

5. **ORDER BY term in parentheses (1.7).** SQLite drops parentheses: `ORDER BY (1)` and
   `ORDER BY ((2))` are column positions (`(2)` with one column is the range error), `-(1)` and `(-1)`
   are the range error, and `SELECT b AS a FROM t ORDER BY (a)` uses the alias. The spec says "an
   integer literal", "`-` directly followed by one" and "a term that is just a name", which reads as
   excluding parentheses; yet 1.9 treats `(s)` as the column itself. The reference follows the spec's
   words (a parenthesised term is an expression). The spec should say which.
6. **"`-` directly followed by" an integer (1.7).** SQLite treats `ORDER BY - 1` (with a space) as
   `-1`. "Directly" could be read as "no space"; the reference treats them alike (token level).
7. **`NOT` as the operand of a tighter operator (1.8).** The level table does not say whether
   `1 = NOT 0` is valid. SQLite accepts it, and `NOT` then takes everything binding tighter than itself:
   `1 = NOT 0 = 0` is `1 = NOT (0 = 0)` = 0, and `- NOT 0` is -1. The reference does the same.
8. **Which spaces are trimmed when storing text (1.5, also 1.9).** The spec says "spaces". SQLite also
   trims tab, newline, CR (`'\t12\n'` stores 12 in an INTEGER column). The reference trims only spaces,
   per the spec's word; the numeric-prefix rule (1.8, "skip leading spaces") has the same question.
9. **Integer text beyond 64 bits (1.5).** "an INTEGER if the literal has no `.` and no exponent": SQLite
   turns `'99999999999999999999'` into a REAL and rejects it with `cannot store REAL value in INTEGER
   column t.a`. Same for the literal `9223372036854775808` (typeof `real`). The reference does as
   SQLite; the spec only promises that tests stay within 64 bits.
10. **A column listed twice in INSERT (1.6).** `INSERT INTO t (a, a) VALUES (7, 8)` stores 7 in SQLite
    (the first value). The spec says nothing; the reference stores the first value.
11. **Two result columns with the same alias (1.7).** `SELECT b AS x, a AS x FROM t ORDER BY x` sorts by
    the first in SQLite. The spec says "that result column"; the reference uses the first.
12. **LIMIT/OFFSET that are not integers (1.7).** SQLite gives `datatype mismatch` (not in the
    catalogue) for `LIMIT 1.5` or `LIMIT NULL`, and accepts `LIMIT '2'`. The spec only says tests use
    integer literals; fine as long as that holds.

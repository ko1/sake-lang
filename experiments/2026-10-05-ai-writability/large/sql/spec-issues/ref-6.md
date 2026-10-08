# Reference implementation, stage 6: where the tests and the specification disagree

Implementation: `large/sql/ref/` (Ruby 4.0.2). Probes ran on SQLite 3.46.1 (python3 `sqlite3`, STRICT
tables, and `harness/sql_oracle.py` where the messages are in the catalogue).
Result (stages 1-6): public 366/366, hidden 368/369 (the one failure is item 1).

New file: `windows.rb` (the window functions, the frame rules and errors of 6.2, a simple-select's
WINDOW clause and window calls (`Windows::Collector`), and their computation per partition). The
parser reads `OVER`, window-specs, frames and `WINDOW`; the Binder allows a window call only where it
is given the query's windows (result columns and ORDER BY), so every other place (WHERE, GROUP BY,
HAVING, ON, the arguments of an aggregate or window call, a window's own terms, UPDATE / DELETE /
INSERT VALUES, LIMIT) reports `misuse of window function <name>()` with no rule of its own.
`SelectQuery` computes the window values on the rows left after WHERE / GROUP BY / HAVING (the group
rows in an aggregate query) and before DISTINCT, ORDER BY and LIMIT.

## A. Tests that disagree with the specification

1. **`tasks/sql-hidden/6/025-no-such-window-base`, statement 5**
   `SELECT a, sum(b) OVER w2 FROM t WINDOW w2 AS (w1 ORDER BY a);` (no window `w1` anywhere).
   - Expected (SQLite): `1|2`.
   - Specified (6.1): "A named window ... can be used ... as the base of a window-spec (`OVER (w ORDER
     BY x)`) ...; an unknown name is `no such window: <name>`." `(w1 ORDER BY a)` is a window-spec
     whose base is the unknown name `w1`, so: `Error: no such window: w1`.
   - Judgement: the test is wrong with respect to the spec. SQLite resolves the base of a window
     definition in a WINDOW clause only against the definitions *before* it in that clause, and
     silently drops a base it does not find there (it checks the base only in `OVER (base ...)`):
     `WINDOW w2 AS (w1)` with no `w1` is the whole partition, no error. Either drop the statement
     (the other four statements cover `no such window`) or say in 6.1 that a base name inside a
     WINDOW clause that is not defined earlier in it is ignored. The reference follows the spec.

No other stage 6 test, public or hidden, disagrees with the spec's words.

## B. Places where SQLite and the specification differ (no test depends on them)

2. **A base defined later in the same WINDOW clause.** `WINDOW w2 AS (w1 ORDER BY a), w1 AS
   (PARTITION BY s)`: SQLite ignores `w1` (see 1) and computes over one partition; 6.1 lets a named
   window be a base without a word on order. The reference looks the base up in the whole clause
   (here: partitioned by `s`). A window that is its own base (directly or through others) is
   `no such window: <name>` in the reference.

## C. Rules that are unclear or missing

Not decided by tests (the reference does what SQLite does unless noted):

3. **When the frame offset errors happen.** SQLite checks a negative (or, under ROWS, non-integer)
   offset when the window runs: on an empty table `SELECT a, sum(a) OVER (ORDER BY a ROWS -1
   PRECEDING) FROM e` prints nothing. Every test has rows. Since 6.1 makes n a literal, the reference
   checks it with the other frame errors before any row is read (so it reports the error on an empty
   table too). 6.2 could say which. (`ntile` and `nth_value` arguments are expressions evaluated per
   row; their errors occur only when a row is computed, as in SQLite.) Order of the frame errors when
   several apply (SQLite, followed by the reference): `unsupported frame specification`, then
   `RANGE with offset ...`, then the starting offset, then the ending offset.
4. **Aliased window misuse outside WHERE.** 6.2 gives `misuse of aliased window function <alias>`
   for WHERE only, and `misuse of window function <name>()` for a window call in GROUP BY / HAVING.
   Through an alias SQLite says the aliased form in all three: `... AS x FROM t GROUP BY x` and
   `... GROUP BY a HAVING x > 0` are `misuse of aliased window function x`. The reference does the
   same; the spec could say "a name in WHERE, GROUP BY or HAVING".
5. **Non-integer arguments.** `ntile(2.5)` acts as `ntile(2)` (truncated; the reference does the
   same); `nth_value(x, 1.0)` and `nth_value(x, '1')` are accepted, `nth_value(x, 1.5)` and a NULL n
   are the error (same in the reference); `ROWS 1.0 PRECEDING` is accepted as 1, `ROWS 1.5
   PRECEDING` is the integer error, `RANGE 1.5 PRECEDING` is allowed. `lag(x, 1.5)` gives NULL on
   every row in SQLite; the reference truncates k to 1. 6.3 says "tests use integer n" for ntile
   only.
6. **RANGE offsets on non-numeric values.** 6.2: "Tests use numeric terms." The reference treats a
   TEXT value like NULL (its frame is its peers), which happens to agree with SQLite on the cases
   tried; SQLite's real rule is not documented in the spec.
7. **Messages not in the catalogue**, for cases tests exclude: `DISTINCT is not supported for window
   functions`, `<name>() may not be used as a window function` (`OVER` on a scalar function, also
   `min(a, b) OVER ()`), `wrong number of arguments to function row_number()` (window functions
   called with the wrong argument count). The reference uses SQLite's.
8. **Aggregates inside a window's arguments or terms make the query an aggregate query.**
   `SELECT sum(sum(a)) OVER () FROM t` is one group (prints the total), and so is `SELECT
   row_number() OVER (PARTITION BY sum(a)) FROM t`. 6.2 shows `sum(sum(x)) OVER` only with GROUP BY;
   3.3's "a query with an aggregate call is an aggregate query" covers it if read literally. The
   reference does what SQLite does.
9. **Duplicate window names** in one WINDOW clause (6.1 says tests do not have them): SQLite accepts
   them and uses the last; so does the reference.

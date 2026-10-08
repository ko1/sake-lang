# Reference implementation, stage 3: where the tests and the specification disagree

Implementation: `large/sql/ref/` (Ruby 4.0.2). Probes ran on SQLite 3.46.1 (python3 `sqlite3`,
STRICT tables). Result (stages 1-3): public 202/202, hidden 205/205.

New files: `aggregates.rb` (the aggregate functions, the aggregate calls of a query) and
`select_query.rb` (SELECT, moved out of `database.rb`: binding of every clause, grouping, HAVING,
DISTINCT). `binder.rb` now binds per clause (which names are visible, whether aggregate calls are
allowed and which misuse message applies).

## A. Tests whose expected output depends on what the specification leaves open

1. **`tasks/sql-hidden/3/057-scenario-election`, statement 2: a bare column with two aggregate calls.**
   ```sql
   SELECT district, sum(n), max(n), candidate FROM votes GROUP BY district ORDER BY district;
   ```
   The `west` group has the rows (kay, 200), (lin, 390), (max, 50). Expected: `west|640|390|lin`.
   Spec 3.3: with more than one aggregate call (here `sum` and `max`) a bare column takes its value
   from "any row of the group", and "tests use a bare column only when every row of the group has the
   same value there, or with that single `min`/`max`". `candidate` differs within the group and the
   query has two calls, so the spec allows `kay`, `lin` or `max`; a conforming engine that takes the
   first row prints `west|640|390|kay`. The oracle did not catch it: `PRAGMA reverse_unordered_selects`
   does not change which row SQLite uses here.
   Judgement: the test is wrong (it relies on an unspecified choice). Either drop `candidate` from that
   statement, or have the spec state SQLite's rule: when the query has a `min`/`max` call, bare columns
   come from the row that gave the extreme of the last such call (with `min` and `max` both present,
   SQLite follows whichever it evaluates last; `SELECT club, name, max(secs) ... HAVING min(secs) > 0`
   gives the minimum's row). The reference passes the test by choosing, among the rows the spec
   allows, that SQLite rule (bare columns take the last `min`/`max` call's row, else the group's first
   row), which agrees with the spec everywhere.

## B. Places where SQLite and the specification differ (no test depends on them)

The reference follows the specification.

2. **`GROUP BY +k` and `GROUP BY (k)` (3.3).** Spec: only an integer literal or `-` followed by one is
   an ordinal, so `+1` and `(1)` are constants (one group). SQLite 3.46 treats both as the k-th
   result column (`SELECT b, count(*) FROM t GROUP BY +1` groups by `b`; `GROUP BY (5)` with two
   columns is `1st GROUP BY term out of range`). The same holds for `ORDER BY +1` and `ORDER BY (2)`,
   which spec 1.7 explicitly calls an expression ("Any other term (including `+1`) is an expression"):
   SQLite sorts by the column. Judgement: the spec contradicts SQLite in 1.7 and 3.3; harmless while
   tests avoid these forms, but the 1.7 example invites a test that the oracle would answer
   against the spec. Either say "tests do not write `+k` or `(k)`" or adopt SQLite's rule.
3. **"Exactly one aggregate call" counts calls, SQLite counts distinct calls (3.3).**
   `SELECT name, max(secs) FROM r ORDER BY max(secs)` has two calls by the spec's count ("calls in
   result columns, HAVING and ORDER BY all count"), so `name` is any row; SQLite merges identical
   calls (one `max`) and takes the maximum's row. The same arises through an alias (`HAVING m > 0`
   with `max(x) AS m`). The reference merges identical calls as SQLite does (allowed by "any row").
   Judgement: say "distinct calls", or "a call written again is the same call".

## C. Rules that are unclear or missing (tests do not decide them)

4. **`group_concat(x, sep)` with a separator that varies by row (3.2).** "joined by sep's text form"
   assumes one sep. SQLite puts each row's own sep before that row's value
   (`group_concat(b, a)` over (1,x),(2,y),(1,z),(3,x) is `x2y1z3x`). The reference does the same.
5. **`DISTINCT` with `ORDER BY` inside one call (3.2).** Which duplicate's ORDER BY key counts?
   SQLite keeps the first occurrence in row order, then sorts:
   `group_concat(DISTINCT b ORDER BY a DESC)` over (a,b) = (1,x),(2,y),(1,z),(3,x) is `y,x,z`, not
   `x,y,z`. The reference does the same. The spec should say so or tests should avoid it.
6. **`count()` with no argument.** The grammar shows only `count(*)`; SQLite accepts `count()` as
   `count(*)`. The reference follows SQLite; `wrong number of arguments` would also be a reading.
7. **`name(*)` for a function other than `count`.** SQLite: `wrong number of arguments to function
   sum()` (any known function), `no such function: foo` otherwise. The spec's grammar makes it a
   syntax error at most by implication. The reference follows SQLite.
8. **`ORDER BY` inside a scalar call** (`upper(x ORDER BY y)`): SQLite's error
   `ORDER BY may not be used with non-aggregate upper()` is not in the catalogue; **`DISTINCT` in a
   scalar call** (`max(DISTINCT a, 1)`) is ignored by SQLite. The spec says tests do not write the
   latter for min/max; it says nothing about either in general. The reference follows SQLite.
9. **Integer overflow in `sum` (3.2).** "if it leaves 64 bits": the reference (like SQLite) fails when
   the running INTEGER sum leaves 64 bits at any point before the first non-INTEGER value, even if a
   later value would bring it back or make the sum REAL. `total` and `avg` never fail (SQLite:
   `total(9223372036854775807)` over 4 rows is `3.68934881474191e+19`).
10. **Wording: "after trimming spaces" (3.2 Sums, also 1.9 rule 1)** refers to the test of 1.5 step 2,
    which trims whitespace (space, tab, newline, CR); SQLite's `sum(char(9) || '3')` is the INTEGER 3.
    Say "whitespace" in both places.

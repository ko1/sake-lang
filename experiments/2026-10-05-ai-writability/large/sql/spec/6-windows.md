# Stage 6: window functions

## 6.1 Syntax

```
window-call := name ( [expr [, expr]...] | * ) OVER ( window-spec ) | name ( ... ) OVER window-name
window-spec := [base-window-name] [PARTITION BY expr [, expr]...] [ORDER BY ordering-term [, ...]] [frame]
frame := (ROWS | RANGE) frame-start | (ROWS | RANGE) BETWEEN frame-start AND frame-end
frame-start, frame-end := UNBOUNDED PRECEDING | n PRECEDING | CURRENT ROW | n FOLLOWING | UNBOUNDED FOLLOWING
SELECT ... [HAVING ...] [WINDOW window-name AS ( window-spec ) [, ...]] [ORDER BY ...] [LIMIT ...]
```

`frame-start` alone means `BETWEEN frame-start AND CURRENT ROW`. n is an integer literal (a
negative one only appears in tests as `-n`, for the errors in 6.2).
A named window (`WINDOW w AS (...)`) can be used as `OVER w`, or as the base of a window-spec
(`OVER (w ORDER BY x)`), which adds to it the parts it does not have (tests add only `ORDER BY` and
a frame to a base that has neither); an unknown name is `no such window: <name>`. Window names are
unquoted identifiers, distinct within one `WINDOW` clause. In a compound select (5.1) each
simple-select has its own `WINDOW` clause, visible only in that simple-select.

Inside a window-spec, `PARTITION BY` and `ORDER BY` terms are plain expressions over the query's
sources: an integer literal there is a constant (not a result column number) and a result column's
alias is not visible.

## 6.2 Where they run

Window calls may appear only in the result columns and the `ORDER BY` of a `SELECT` (also inside
other expressions there, such as `abs(row_number() OVER (...))` or `rank() OVER (...) * 10`). In
`WHERE`, `GROUP BY` or `HAVING`, or inside the arguments of an aggregate or window call, a window
call is `misuse of window function <name>()`. A name in `WHERE` that is the alias of a result column
containing a window call is `misuse of aliased window function <alias>`. They are computed after `WHERE`, `GROUP BY` and `HAVING`, over the rows that the query
would otherwise produce (one per group in an aggregate query, where a window's expressions may use
aggregate calls, e.g. `rank() OVER (ORDER BY sum(x) DESC)`), and before `DISTINCT`, the final
`ORDER BY`, `LIMIT` and `OFFSET`.

For each window call: the rows are divided into **partitions** by the `PARTITION BY` values (equal
as in `GROUP BY`; one partition without it), and each partition is sorted by the window's `ORDER BY`
(rows that tie are **peers**; without `ORDER BY`, all rows of the partition are peers and their order
is unspecified: tests then use only functions that do not depend on it). Each row's result depends on
its partition, its position, and its **frame**, a range of rows of the partition:

- Without a frame clause: with `ORDER BY`, from the partition's first row to the current row's last
  peer; without `ORDER BY`, the whole partition.
- `ROWS`: positions. `n PRECEDING`/`n FOLLOWING` are the row n positions before/after the current
  row (clipped to the partition), `CURRENT ROW` is the current row, `UNBOUNDED` the partition's
  first/last row.
- `RANGE`: peers and values. `CURRENT ROW` as a start means the current row's first peer, as an end
  its last peer. `n PRECEDING`/`n FOLLOWING` require exactly one `ORDER BY` term (else `RANGE with
  offset PRECEDING/FOLLOWING requires one ORDER BY expression`) and mean the first/last row whose
  value of that term is within n below/above the current row's value (with `DESC`, above/below);
  rows whose term is NULL are within any range of a NULL current value only. Tests use numeric terms.
- A frame whose start is `CURRENT ROW` and end is `n PRECEDING`, or whose start is `n FOLLOWING` and
  end is `CURRENT ROW` or `n PRECEDING`, is `unsupported frame specification` (this includes a
  start alone of `n FOLLOWING`). Otherwise a frame whose start comes after its end (`ROWS BETWEEN 1
  PRECEDING AND 2 PRECEDING`, `ROWS BETWEEN 2 FOLLOWING AND 1 FOLLOWING`) is empty.
- A negative offset is, under `ROWS`, `frame starting offset must be a non-negative integer` or
  `frame ending offset must be a non-negative integer`; under `RANGE`, the same with `number` in
  place of `integer`. A start of `UNBOUNDED FOLLOWING` or an end of `UNBOUNDED PRECEDING` does not
  occur in tests.

## 6.3 Window functions

The aggregates of 3.2 (`count`, `sum`, `total`, `avg`, `min`, `max`, `group_concat`, without
`DISTINCT` or an inner `ORDER BY`) used with `OVER` compute over the frame, adding the frame's rows
in partition order. In addition:

| function | result for the current row (positions are 1-based within the partition) |
|---|---|
| `row_number()` | its position |
| `rank()` | the position of its first peer (1 without `ORDER BY`) |
| `dense_rank()` | the number of distinct peer groups up to and including its own |
| `percent_rank()` | (rank - 1) / (rows in partition - 1) as REAL; 0.0 for a one-row partition |
| `cume_dist()` | (position of its last peer) / (rows in partition) as REAL |
| `ntile(n)` | the bucket 1..n of the row when the partition's rows, in order, are split into n buckets whose sizes differ by at most 1, larger buckets first; n NULL, zero or negative is `argument of ntile must be a positive integer` (tests use integer n) |
| `lag(x)`, `lag(x, k)`, `lag(x, k, d)` | x evaluated on the row k positions earlier in the partition (k defaults to 1; a negative k means -k positions later; a NULL k gives NULL), or else d (default NULL) evaluated on the current row |
| `lead(x)`, `lead(x, k)`, `lead(x, k, d)` | the same, k positions later |
| `first_value(x)`, `last_value(x)` | x on the frame's first / last row; NULL if the frame is empty |
| `nth_value(x, n)` | x on the frame's n-th row; NULL if it has fewer rows; n not a positive integer is `second argument to nth_value must be a positive integer` |

`rank`, `dense_rank`, `percent_rank`, `cume_dist`, `ntile`, `row_number`, `lag` and `lead` ignore the
frame. Calling one of these names without `OVER` is `misuse of window function <name>()` (for the
names that are not also aggregates). Tests do not use `OVER` with other functions, `DISTINCT` in a
window aggregate, or a window-spec that overrides its base's `PARTITION BY` or `ORDER BY`.

## 6.4 Errors added in this stage

`misuse of window function <name>()`; `misuse of aliased window function <alias>`; `no such window: <name>`;
`unsupported frame specification`; `frame starting offset must be a non-negative number`;
`frame ending offset must be a non-negative number`; `second argument to nth_value must be a positive integer`;
`RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression`;
`frame starting offset must be a non-negative integer`; `frame ending offset must be a non-negative
integer`; `argument of ntile must be a positive integer`.

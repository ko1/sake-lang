# c1-collate: notes on change-hard.md

## Check against the hidden tests (`tasks/sql-change-hidden/c1-collate/7/`, 48 tests)

Each test's `.out` was traced by hand from spec 1-6 and change-hard.md. All 48 follow; no rule had to
be added after the check. Points that needed care while tracing:

- 002 `r COLLATE NOCASE = ' 2.5 '` is 1: REAL affinity of `r` (kept by `COLLATE`, 7.2) converts the
  text first (1.9); collation never applies to a number (7.1).
- 020, 017, 029: a term naming a result column by number or alias takes that column's collation, and
  may take its own `COLLATE` (7.2 syntax bullet + 7.4 "A term that stands for a result column").
- 027, 043: window `min`/`max` and peers follow "values of one expression compared among themselves"
  (smallest/largest; ties are the same value).
- 028, 030, 048: three-way and two-way compounds: "first simple-select, left to right, that gives the
  column a collation" (7.4 whole rows).
- 035 `up = ci` uses BINARY: a view column with no collation is implicit BINARY and wins on the left.
  The original says this only implicitly ("gives a column whose collation is BINARY"); change-hard.md
  states the consequence with an example (7.5). Not a missing rule, an emphasis.
- 038 `(SELECT val COLLATE NOCASE ...) = 'high'` is 0: change-hard.md says a scalar subquery has none
  even with an explicit `COLLATE` in it (the original's "whatever its result column is").
- 041 `USING`: 4.1 defines `USING (c)` as `ON A.c = B.c`, so the general "construct defined as a
  comparison a op b" rule gives the left side's column collation.
- 046 `login IN (SELECT 'CLEO' UNION ALL SELECT 'dion')`: the left column's implicit collation wins
  over anything the compound could give, so the compound-as-subquery case is not exercised.

## Sites of the original's "Where it applies" and the rule they follow from

| site | rule in change-hard.md |
|---|---|
| syntax | 7.2 (column constraint in any statement defining a column, postfix operator binding and value/affinity, case-insensitive names, unknown-name error) |
| compare | 7.4 "Two expressions compared with each other" (explicit left/right, implicit left/right, BINARY) + 7.1; `LIKE` / functions: 7.6 |
| between | 7.4 two-expression rule through 2.3's definition `x >= a AND x <= b` (example kept) |
| in-list | 7.4 exception 1 (`x IN (list)`: only x) |
| in-subquery | 7.4 exception 2 (`x IN (select)` as `x = e`) |
| case | 7.4 two-expression rule through 2.3's definition of `CASE x WHEN v` as `x = v` |
| order-by | 7.4 "values of one expression compared among themselves" (order) + "a term that stands for a result column" + 7.2 (`COLLATE` after a number/alias) |
| group-by | 7.4 "values of one expression ..." (same values fall together) + result-column term rule; unspecified representative: 7.1 last paragraph |
| distinct | 7.4 "Whole rows compared" (simple select: result column expression's collation) |
| agg-distinct | 7.4 "values of one expression ..." (count once where distinct values are counted); restriction to `count` kept |
| min-max | 7.4 "values of one expression ..." (smallest or largest) |
| compound | 7.4 "Whole rows compared", compound bullet (column collation, set comparison and sort, sort-term `COLLATE`) |
| unique | 7.4 "Stored values compared for uniqueness" (each column its own collation, every way a row is stored) |
| index | 7.4 "Stored values compared for uniqueness" (index column `COLLATE`, error on existing conflicts) + 7.2 unknown name in an index column |
| sources | 7.5 + 7.3 column reference bullet |
| scalar-subquery | 7.3 scalar subquery bullet |
| join | 7.4 two-expression rule (`ON` is ordinary comparisons; `USING` through 4.1's `ON A.c = B.c`) |
| window | 7.4 "values of one expression ..." (order, partitions, peers as ties) |
| alter | 7.2 column collation "in every statement that defines a column ... from then on" + unknown name "creates or adds nothing" |

## Rules that still name a construct

These exist for one construct only and are stated as that rule: the two `IN` exceptions, the scalar
subquery having no collation, the compound's column collation, the `UNIQUE` index's `COLLATE`, the
aggregate `DISTINCT` restriction to `count`, and `LIKE` ignoring collations. `BETWEEN` appears only as an example of the general rule and `CASE x WHEN`
not at all (both are defined as comparisons in 2.3).

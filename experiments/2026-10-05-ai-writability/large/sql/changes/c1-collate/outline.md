# c1 collating sequences (wide)

Collations BINARY (the default, byte order), NOCASE (ASCII letters folded to lower case before comparing) and
RTRIM (trailing spaces ignored). A column definition may say `COLLATE <name>`; an expression may be followed by
`COLLATE <name>` (postfix operator, binds tighter than any binary operator). Unknown name: SQLite's error.
Which collation a comparison uses: SQLite's rules (an explicit COLLATE on either operand, the left one first;
otherwise the collation of a column operand, the left one first; otherwise BINARY). Only TEXT comparisons are
affected.

It applies everywhere the engine compares or groups text. Candidate sites (verify each with SQLite, keep the
ones whose behaviour is clear, give each an id): comparison operators, BETWEEN, IN (list and subquery), CASE x
WHEN, ORDER BY terms (column collation or COLLATE on the term), GROUP BY, SELECT DISTINCT, count/group_concat
DISTINCT, min/max (aggregate), UNION/INTERSECT/EXCEPT (dedupe and order), UNIQUE and PRIMARY KEY constraints
(column collation), indexes (UNIQUE index on a NOCASE column), views and subqueries carrying a column's
collation, joins (ON and USING), window PARTITION BY and ORDER BY, ALTER TABLE ADD COLUMN ... COLLATE.

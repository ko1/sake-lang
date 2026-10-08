CREATE TABLE t (a INTEGER, b INTEGER);
INSERT INTO t VALUES (1, 10), (2, 20), (3, 30);
SELECT a * 2 AS d FROM t WHERE d > 2 ORDER BY d;
SELECT a, b - a AS diff FROM t WHERE diff >= 18 ORDER BY a;
-- A table column comes before an alias of the same name.
SELECT b AS a FROM t WHERE a > 1 ORDER BY b;
SELECT a + b total FROM t WHERE total = 22;
SELECT a FROM t WHERE missing = 1;

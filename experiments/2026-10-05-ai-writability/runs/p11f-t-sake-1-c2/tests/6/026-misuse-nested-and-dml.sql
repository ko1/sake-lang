-- a window call inside another window or aggregate call, or in UPDATE/INSERT/DELETE
CREATE TABLE t (a INTEGER, b INTEGER);
INSERT INTO t VALUES (1, 10), (2, 20), (3, 30);
SELECT a, sum(row_number() OVER (ORDER BY a)) OVER () FROM t;
SELECT max(rank() OVER (ORDER BY b)) FROM t;
UPDATE t SET b = row_number() OVER (ORDER BY a);
INSERT INTO t VALUES (4, ntile(2) OVER ());
DELETE FROM t WHERE lag(a) OVER (ORDER BY a) IS NULL;
SELECT a, b FROM t ORDER BY a;

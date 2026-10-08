-- the select is fully computed before any row is inserted
CREATE TABLE t (n INTEGER);
INSERT INTO t VALUES (1), (2);
INSERT INTO t SELECT n + 2 FROM t;
SELECT n FROM t ORDER BY n;
INSERT INTO t SELECT n * 10 FROM t;
SELECT count(*), max(n) FROM t;
INSERT INTO t SELECT max(n) + 1 FROM t;
SELECT n FROM t ORDER BY n DESC LIMIT 2;

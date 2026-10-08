-- SELECT DISTINCT printing values where every member of a duplicate set is identical.
CREATE TABLE t (k TEXT COLLATE NOCASE, v INTEGER);
INSERT INTO t VALUES ('x', 1), ('X', 1), ('y', 2), ('y', 2), ('Z', 3);
SELECT DISTINCT v FROM t ORDER BY v;
SELECT DISTINCT v, upper(k) FROM t ORDER BY 1;
SELECT count(*) FROM (SELECT DISTINCT k, v FROM t);
SELECT count(*) FROM (SELECT DISTINCT k COLLATE BINARY FROM t);

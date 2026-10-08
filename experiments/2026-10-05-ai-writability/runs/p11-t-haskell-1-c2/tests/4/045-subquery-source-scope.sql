-- A subquery in FROM runs once: it cannot see the other sources of the same FROM.
CREATE TABLE t (a INTEGER);
CREATE TABLE u (b INTEGER);
INSERT INTO t VALUES (1), (2);
INSERT INTO u VALUES (2), (3);
SELECT * FROM t, (SELECT t.a AS z) s;
SELECT * FROM t JOIN (SELECT b FROM u WHERE b > a) s ON 1;
SELECT a, b FROM t JOIN (SELECT b FROM u WHERE b > 2) s ON 1 ORDER BY a;
SELECT a, (SELECT count(*) FROM (SELECT b FROM u WHERE b >= 2)) FROM t ORDER BY a;

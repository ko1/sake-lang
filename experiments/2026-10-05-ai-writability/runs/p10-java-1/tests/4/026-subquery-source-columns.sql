-- Subquery source columns are named by alias, else by the column name of a plain column reference.
CREATE TABLE t (a INTEGER, b TEXT);
INSERT INTO t VALUES (1, 'one'), (2, 'two');
SELECT s.a, s.b FROM (SELECT a, b FROM t) s ORDER BY s.a;
SELECT s.x FROM (SELECT a AS x FROM t) s ORDER BY 1;
SELECT s.a FROM (SELECT a AS x FROM t) s;
SELECT a FROM (SELECT a AS x FROM t);
SELECT s.b FROM (SELECT t.b FROM t) AS s ORDER BY 1 DESC;
SELECT y, z FROM (SELECT a + 1 AS y, upper(b) AS z FROM t) ORDER BY y;
SELECT s.* FROM (SELECT b, a FROM t WHERE a = 2) AS s;

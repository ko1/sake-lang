CREATE TABLE t (x INTEGER, y INTEGER, name TEXT);
INSERT INTO t VALUES (1, 40, 'd'), (2, 30, 'c'), (3, 20, 'b'), (4, 10, 'a');
SELECT y AS x FROM t ORDER BY x;
SELECT x, name AS y FROM t ORDER BY y;
SELECT name FROM t ORDER BY y DESC;
SELECT x * -1 AS k, name FROM t ORDER BY k LIMIT 2;
SELECT x AS name, name AS x FROM t ORDER BY name DESC;
SELECT name, x + y AS total FROM t ORDER BY total, name;
SELECT x FROM t ORDER BY nonexistent;

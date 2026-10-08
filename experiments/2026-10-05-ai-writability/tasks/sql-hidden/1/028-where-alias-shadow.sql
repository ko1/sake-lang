CREATE TABLE t (x INTEGER, y INTEGER);
INSERT INTO t VALUES (1, 5), (2, 4), (3, 3), (4, 2);
SELECT x + y AS s, x FROM t WHERE s = 6 AND x > 2 ORDER BY x;
SELECT y AS x FROM t WHERE x = 1;
SELECT x * 10 AS y FROM t WHERE y < 4 ORDER BY 1;
SELECT x AS a, y AS b FROM t WHERE a > b ORDER BY a;
SELECT upper('k' || x) AS code FROM t WHERE code = 'K3';
SELECT x FROM t WHERE z > 0;
SELECT x AS z FROM t WHERE z > 3;

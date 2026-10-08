-- a view's column names: the list, else as for a subquery source
CREATE TABLE t (a INTEGER, b TEXT);
INSERT INTO t VALUES (1, 'x'), (2, 'y');
CREATE VIEW v1 (num, letter) AS SELECT a, b FROM t;
SELECT letter, num FROM v1 ORDER BY num;
SELECT a FROM v1;
CREATE VIEW v2 AS SELECT a, b AS bb, a * 2 AS dbl FROM t;
SELECT a, bb, dbl FROM v2 ORDER BY a;
SELECT b FROM v2;
SELECT v2.dbl FROM v2 WHERE v2.a = 2;

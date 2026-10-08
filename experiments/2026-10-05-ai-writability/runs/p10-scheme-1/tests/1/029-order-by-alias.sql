CREATE TABLE t (a INTEGER, b INTEGER, c TEXT);
INSERT INTO t VALUES (1, 30, 'p'), (2, 10, 'q'), (3, 20, 'r');
SELECT c, b AS k2 FROM t ORDER BY k2;
-- In ORDER BY an alias wins over a table column of the same name.
SELECT b AS a, c FROM t ORDER BY a;
SELECT c AS b, a FROM t ORDER BY b DESC;
SELECT a, c FROM t ORDER BY b;
SELECT -a AS neg FROM t ORDER BY neg;

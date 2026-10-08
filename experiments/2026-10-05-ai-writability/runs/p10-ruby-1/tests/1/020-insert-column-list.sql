CREATE TABLE t (a INTEGER, b TEXT, c REAL);
INSERT INTO t (c, a) VALUES (1.5, 1);
INSERT INTO t (b) VALUES ('only b');
INSERT INTO t (a, b, c) VALUES (3, 'x', 3), (4, 'y', 4.5);
INSERT INTO t VALUES (5, 'all', 0.5);
INSERT INTO t (B, A) VALUES ('mixed case', 6);
SELECT a, b, c FROM t ORDER BY a NULLS FIRST;

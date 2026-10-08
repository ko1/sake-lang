-- creating a UNIQUE index on rows that already conflict fails and creates nothing
CREATE TABLE t (a INTEGER, b INTEGER);
INSERT INTO t VALUES (1, 1), (1, 2), (2, 2);
CREATE UNIQUE INDEX ua ON t (a);
CREATE UNIQUE INDEX ub ON t (b, a);
CREATE UNIQUE INDEX uba ON t (b);
DROP INDEX ua;
DROP INDEX uba;
INSERT INTO t VALUES (1, 2);
DELETE FROM t WHERE a = 1 AND b = 1;
CREATE UNIQUE INDEX ua ON t (a);
SELECT a, b FROM t ORDER BY a, b;
DELETE FROM t WHERE a = 2;
CREATE UNIQUE INDEX ua ON t (a);
INSERT INTO t VALUES (1, 5);
SELECT count(*) FROM t;

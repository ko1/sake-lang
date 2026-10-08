-- a UNIQUE index is checked before the constraints that existed when it was created
CREATE TABLE t (a INTEGER UNIQUE, b INTEGER, c INTEGER, UNIQUE (b));
INSERT INTO t VALUES (1, 1, 1);
INSERT INTO t VALUES (1, 1, 2);
CREATE UNIQUE INDEX tc ON t (c);
INSERT INTO t VALUES (1, 1, 1);
INSERT INTO t VALUES (1, 1, 2);
CREATE UNIQUE INDEX tac ON t (a, c);
INSERT INTO t VALUES (1, 1, 1);
INSERT INTO t VALUES (1, 2, 3);
INSERT INTO t VALUES (2, 1, 3);
SELECT a, b, c FROM t;

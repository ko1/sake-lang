-- NOT NULL of every column is checked before storage conversion
CREATE TABLE t (a INTEGER, b TEXT NOT NULL, c INTEGER);
INSERT INTO t VALUES ('abc', NULL, 1);
INSERT INTO t VALUES ('abc', 'ok', 1);
INSERT INTO t VALUES (1, 'ok', 'abc');
INSERT INTO t VALUES (1.5, 'ok', 2.5);
INSERT INTO t VALUES (1, 'ok', 2);
SELECT * FROM t;

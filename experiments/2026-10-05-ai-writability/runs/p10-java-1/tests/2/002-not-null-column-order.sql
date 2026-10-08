-- with several NOT NULL columns failing, the first in column order is reported
CREATE TABLE t (a INTEGER, b TEXT NOT NULL, c REAL NOT NULL, d INTEGER NOT NULL);
INSERT INTO t VALUES (1, NULL, NULL, NULL);
INSERT INTO t VALUES (1, 'x', NULL, NULL);
INSERT INTO t (a, b, c) VALUES (1, 'x', 2.5);
INSERT INTO t (d, a) VALUES (4, 1);
INSERT INTO t VALUES (NULL, 'x', 2.5, 4);
SELECT * FROM t;

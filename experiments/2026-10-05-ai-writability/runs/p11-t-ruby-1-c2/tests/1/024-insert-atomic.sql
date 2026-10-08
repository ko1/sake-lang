-- A multi-row INSERT that fails on any row inserts nothing.
CREATE TABLE t (id INTEGER, v INTEGER);
INSERT INTO t VALUES (1, 10), (2, 20), (3, 'bad'), (4, 40);
SELECT * FROM t;
INSERT INTO t VALUES (1, 10), (2, 20);
INSERT INTO t VALUES (3, 30), (4, 4.5);
INSERT INTO t VALUES (5, 50), (6, nosuch);
INSERT INTO t (id, v) VALUES (7, 70), (8, 80);
SELECT id, v FROM t ORDER BY id;

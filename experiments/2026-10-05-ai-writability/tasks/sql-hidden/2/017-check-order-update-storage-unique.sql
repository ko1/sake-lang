CREATE TABLE t (id INTEGER UNIQUE, v REAL NOT NULL);
INSERT INTO t VALUES (1, 1.0), (2, 2.0);
UPDATE t SET id = 1, v = 'abc' WHERE id = 2;
UPDATE t SET id = 1, v = NULL WHERE id = 2;
UPDATE t SET id = '1.5', v = 3 WHERE id = 2;
UPDATE t SET id = 1, v = 3 WHERE id = 2;
UPDATE t SET id = 3, v = '3' WHERE id = 2;
SELECT id, v FROM t ORDER BY id;

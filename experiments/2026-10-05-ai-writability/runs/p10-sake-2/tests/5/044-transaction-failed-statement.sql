-- a statement that fails inside a transaction has no effect; the transaction stays open
CREATE TABLE t (id INTEGER UNIQUE, n TEXT NOT NULL);
BEGIN;
INSERT INTO t VALUES (1, 'a');
INSERT INTO t VALUES (2, 'b'), (1, 'c');
INSERT INTO t VALUES (3, NULL);
INSERT INTO t VALUES (2, 'b');
UPDATE t SET id = 5;
SELECT nosuch FROM t;
INSERT INTO t VALUES (4, 'd');
BEGIN;
SELECT id, n FROM t ORDER BY id;
ROLLBACK;
SELECT count(*) FROM t;

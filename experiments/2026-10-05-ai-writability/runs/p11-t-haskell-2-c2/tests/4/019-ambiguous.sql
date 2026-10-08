-- An unqualified name that two sources have is ambiguous wherever it appears.
CREATE TABLE t (id INTEGER, v TEXT);
CREATE TABLE u (id INTEGER, w TEXT);
INSERT INTO t VALUES (1, 'a'), (2, 'b');
INSERT INTO u VALUES (2, 'c'), (3, 'd');
SELECT id FROM t, u;
SELECT v, w FROM t JOIN u ON id = 2;
SELECT v FROM t JOIN u ON t.id = u.id WHERE id > 0;
SELECT v FROM t JOIN u ON t.id = u.id ORDER BY id;
SELECT count(*) FROM t, u GROUP BY id;
SELECT v, w FROM t JOIN u ON t.id = u.id;
SELECT t.id, w FROM t, u WHERE t.id < u.id ORDER BY t.id, w;
SELECT u.id AS id, v FROM t JOIN u ON t.id = u.id ORDER BY id;

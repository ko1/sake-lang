SELECT nullif(1, 1), nullif(1, 2), nullif('a', 'a');
SELECT nullif(1, 1.0), nullif('1', 1), nullif(1, '1');
SELECT nullif(NULL, 1), nullif(1, NULL);
SELECT typeof(nullif(2, 2)), nullif('a', 'A');
CREATE TABLE t (id INTEGER, s TEXT, i INTEGER);
INSERT INTO t VALUES (1, '10', 10), (2, '', 0), (3, 'x', 5);
SELECT id, nullif(s, 10), nullif(s, '10'), nullif(i, '10') FROM t ORDER BY id;
SELECT id, nullif(s, '') FROM t ORDER BY id;
SELECT id, 100 / nullif(i, 0) FROM t ORDER BY id;

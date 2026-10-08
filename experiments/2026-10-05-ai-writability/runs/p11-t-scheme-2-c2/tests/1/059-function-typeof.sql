SELECT typeof(NULL), typeof(1), typeof(1.0), typeof('1');
SELECT typeof(1 + 1), typeof(1 + 1.0), typeof('1' + 1), typeof(1 || 1);
SELECT typeof(1 / 0), typeof(1e3), typeof(-'x');
SELECT typeof(typeof(NULL)), TYPEOF(2.5);
CREATE TABLE t (i INTEGER, r REAL, s TEXT);
INSERT INTO t VALUES (1, 1, 1), (NULL, '2', '2'), (3.0, NULL, NULL);
SELECT typeof(i), typeof(r), typeof(s) FROM t ORDER BY i NULLS FIRST;

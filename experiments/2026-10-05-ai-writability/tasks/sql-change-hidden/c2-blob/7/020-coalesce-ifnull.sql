CREATE TABLE r (id INTEGER, a BLOB, b BLOB);
INSERT INTO r VALUES (1, NULL, X'0B'), (2, X'0A', X'0B'), (3, NULL, NULL);
SELECT id, coalesce(a, b, X'FF'), ifnull(a, 'none') FROM r ORDER BY id;
SELECT typeof(coalesce(NULL, X'')), coalesce(X'', 1);

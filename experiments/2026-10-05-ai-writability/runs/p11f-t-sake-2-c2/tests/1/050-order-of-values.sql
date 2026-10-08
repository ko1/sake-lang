-- NULL < numbers < text, in comparisons and in sorting.
SELECT NULL < 1, 1 < 'a', 100 < '1', 2.5 < 3, 3 > 2.5;
SELECT 99999 < '', 1 < ' ';
CREATE TABLE t (id INTEGER, r REAL, s TEXT);
INSERT INTO t VALUES (1, 2.5, NULL), (2, NULL, 'apple'), (3, NULL, NULL), (4, -1, NULL), (5, NULL, '10'), (6, 3, NULL);
SELECT id, coalesce(r, s) AS v FROM t ORDER BY v, id;
SELECT id, coalesce(r, s) AS v FROM t ORDER BY v DESC, id;
SELECT id FROM t ORDER BY coalesce(s, r) NULLS LAST, id;
SELECT id FROM t WHERE coalesce(r, s) > 2 ORDER BY id;

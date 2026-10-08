CREATE TABLE ev (id INTEGER, dev BLOB, n INTEGER);
INSERT INTO ev VALUES (1, X'0A', 5), (2, X'0B', 3), (3, X'0A', 7), (4, X'0B', 1), (5, X'0A', 2);
SELECT id, dev, sum(n) OVER (PARTITION BY dev ORDER BY id), row_number() OVER (PARTITION BY dev ORDER BY id) FROM ev ORDER BY id;
SELECT id, count(*) OVER (PARTITION BY dev) FROM ev ORDER BY id;

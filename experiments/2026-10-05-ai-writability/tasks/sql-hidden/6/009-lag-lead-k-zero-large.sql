CREATE TABLE z (i INTEGER, v INTEGER);
INSERT INTO z VALUES (1, 10), (2, NULL), (3, 30), (4, 40);
SELECT i, lag(v, 0) OVER (ORDER BY i), lead(v, 0, -1) OVER (ORDER BY i) FROM z ORDER BY i;
SELECT i, lag(v, 3) OVER (ORDER BY i), lead(v, 3, 0) OVER (ORDER BY i), lag(v, 4, 'x') OVER (ORDER BY i) FROM z ORDER BY i;
-- a NULL value on an existing row is not replaced by the default
SELECT i, lag(v, 1, 99) OVER (ORDER BY i), lead(v, 1, 99) OVER (ORDER BY i) FROM z ORDER BY i;
SELECT i, lead(i * 100, 2, NULL) OVER (ORDER BY i DESC) FROM z ORDER BY i;

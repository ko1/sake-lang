CREATE TABLE kv (k TEXT, v TEXT);
INSERT INTO kv VALUES ('a', 'x'), ('a', 'y'), ('b', 'x');
SELECT k, group_concat(DISTINCT v, '|' ORDER BY v) FROM kv GROUP BY k;
SELECT k FROM kv GROUP BY k HAVING group_concat(DISTINCT v, '') = 'x';
SELECT k FROM kv GROUP BY k ORDER BY group_concat(DISTINCT v, '+');
SELECT k, group_concat(DISTINCT v ORDER BY v) FROM kv GROUP BY k ORDER BY k;

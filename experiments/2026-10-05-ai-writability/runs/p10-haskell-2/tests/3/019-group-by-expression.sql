CREATE TABLE nums (n INTEGER);
INSERT INTO nums VALUES (1), (2), (3), (4), (5), (6), (7);
SELECT n % 3, count(*), sum(n) FROM nums GROUP BY n % 3 ORDER BY n % 3;
SELECT n > 4, group_concat(n, '' ORDER BY n) FROM nums GROUP BY n > 4 ORDER BY 1;
SELECT CASE WHEN n < 3 THEN 'low' ELSE 'high' END AS band, count(*) FROM nums GROUP BY CASE WHEN n < 3 THEN 'low' ELSE 'high' END ORDER BY band;
SELECT n / 3 * 3, min(n), max(n) FROM nums GROUP BY n / 3 ORDER BY 1;

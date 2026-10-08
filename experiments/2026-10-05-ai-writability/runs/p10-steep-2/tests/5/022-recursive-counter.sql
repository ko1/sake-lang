-- a recursive cte that counts
WITH RECURSIVE cnt(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM cnt WHERE n < 6) SELECT n FROM cnt ORDER BY n;
WITH RECURSIVE cnt(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM cnt WHERE n < 100) SELECT count(*), sum(n) FROM cnt;
WITH RECURSIVE pw(i, p) AS (SELECT 0, 1 UNION ALL SELECT i + 1, p * 2 FROM pw WHERE i < 10) SELECT p FROM pw WHERE i = 10;
WITH RECURSIVE down(n) AS (SELECT 5 UNION ALL SELECT n - 2 FROM down WHERE n > 0) SELECT group_concat(n) FROM down;

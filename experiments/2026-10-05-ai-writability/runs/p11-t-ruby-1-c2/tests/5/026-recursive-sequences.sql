-- recursive ctes computing sequences with several columns
WITH RECURSIVE fib(i, a, b) AS (SELECT 1, 0, 1 UNION ALL SELECT i + 1, b, a + b FROM fib WHERE i < 12) SELECT i, a FROM fib WHERE i > 8 ORDER BY i;
WITH RECURSIVE fact(n, f) AS (SELECT 1, 1 UNION ALL SELECT n + 1, f * (n + 1) FROM fact WHERE n < 10) SELECT f FROM fact ORDER BY n DESC LIMIT 1;
WITH RECURSIVE halves(x) AS (SELECT 1.0 UNION ALL SELECT x / 2 FROM halves WHERE x > 0.1) SELECT x FROM halves ORDER BY x;
WITH RECURSIVE coll(n, steps) AS (SELECT 6, 0 UNION ALL SELECT CASE WHEN n % 2 = 0 THEN n / 2 ELSE 3 * n + 1 END, steps + 1 FROM coll WHERE n > 1) SELECT max(steps) FROM coll;

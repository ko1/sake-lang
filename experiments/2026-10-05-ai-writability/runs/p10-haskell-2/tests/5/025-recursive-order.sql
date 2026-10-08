-- a recursive cte's rows come in the order they were added to the result (a queue)
WITH RECURSIVE q(n, s) AS (SELECT 1, 'a' UNION ALL SELECT n + 1, s || 'b' FROM q WHERE n < 4) SELECT group_concat(s, '|') FROM q;
WITH RECURSIVE q(n) AS (SELECT 10 UNION ALL SELECT n / 2 FROM q WHERE n > 1) SELECT group_concat(n, ' ') FROM q;
WITH RECURSIVE q(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM q WHERE n < 5) SELECT group_concat(n, '') FROM q WHERE n % 2 = 1;

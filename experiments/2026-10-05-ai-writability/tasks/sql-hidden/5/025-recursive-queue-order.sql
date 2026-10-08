-- the result of a recursive cte is in queue order, which group_concat follows
WITH RECURSIVE t(n, label) AS (SELECT 1, 'one' UNION ALL SELECT n + 1, CASE n + 1 WHEN 2 THEN 'two' WHEN 3 THEN 'three' ELSE 'many' END FROM t WHERE n < 4) SELECT group_concat(label, ' ') FROM t;
WITH RECURSIVE t(n) AS (SELECT 3 UNION ALL SELECT n - 1 FROM t WHERE n > -2) SELECT group_concat(n, ';') FROM t WHERE n <> 0;
WITH RECURSIVE t(n) AS (SELECT 1 UNION ALL SELECT n * 3 FROM t WHERE n < 200) SELECT group_concat(n), count(*), max(n) FROM t;
WITH RECURSIVE t(x) AS (SELECT 'z' UNION SELECT CASE x WHEN 'z' THEN 'y' WHEN 'y' THEN 'x' ELSE 'z' END FROM t) SELECT group_concat(x, '') FROM t;

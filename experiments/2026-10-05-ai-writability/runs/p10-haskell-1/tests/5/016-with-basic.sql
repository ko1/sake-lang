-- a common table expression is a temporary named source for one statement
CREATE TABLE orders (id INTEGER, cust TEXT, amount INTEGER);
INSERT INTO orders VALUES (1, 'ann', 50), (2, 'bob', 20), (3, 'ann', 30), (4, 'cid', 70);
WITH big AS (SELECT id, cust FROM orders WHERE amount >= 30) SELECT id, cust FROM big ORDER BY id;
WITH tot AS (SELECT cust, sum(amount) AS s FROM orders GROUP BY cust) SELECT cust FROM tot WHERE s > 40 ORDER BY cust;
WITH one AS (SELECT 42 AS v) SELECT v + 1 FROM one;
SELECT count(*) FROM big;
WITH x AS (SELECT cust FROM orders), y AS (SELECT DISTINCT cust FROM x) SELECT count(*) FROM x, y;

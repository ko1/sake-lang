-- A ( select ) in FROM is a source whose columns are its result columns.
CREATE TABLE orders (id INTEGER, cust TEXT, total INTEGER);
INSERT INTO orders VALUES (1, 'ann', 30), (2, 'bob', 10), (3, 'ann', 25), (4, 'cid', 50), (5, 'bob', 5);
SELECT s.cust, s.spent FROM (SELECT cust, sum(total) AS spent FROM orders GROUP BY cust) AS s
  ORDER BY s.spent DESC;
SELECT cust, n FROM (SELECT cust, count(*) AS n FROM orders GROUP BY cust) s WHERE n > 1 ORDER BY cust;
SELECT big.id FROM (SELECT id, total FROM orders WHERE total >= 25) big ORDER BY big.total;
SELECT o.id, t.spent FROM orders o JOIN (SELECT cust, sum(total) AS spent FROM orders GROUP BY cust) t
  ON t.cust = o.cust WHERE o.total * 2 > t.spent ORDER BY o.id;
SELECT max(n) FROM (SELECT count(*) AS n FROM orders GROUP BY cust) AS c;

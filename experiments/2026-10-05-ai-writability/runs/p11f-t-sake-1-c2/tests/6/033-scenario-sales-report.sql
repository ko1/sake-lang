-- scenario: monthly sales per store, with running totals, ranks and month-over-month change
CREATE TABLE store (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, city TEXT);
CREATE TABLE sales (store_id INTEGER NOT NULL, month INTEGER NOT NULL, revenue INTEGER, PRIMARY KEY (store_id, month));
INSERT INTO store (name, city) VALUES ('north', 'leeds'), ('south', 'bath'), ('east', 'leeds');
INSERT INTO sales VALUES (1,1,100),(1,2,120),(1,3,90),(2,1,80),(2,2,80),(2,3,150),(3,1,60),(3,2,NULL),(3,3,70);
INSERT INTO sales VALUES (1,3,95);
SELECT count(*) FROM sales;
-- running revenue per store
SELECT s.name, m.month, m.revenue, sum(m.revenue) OVER (PARTITION BY m.store_id ORDER BY m.month) AS running
  FROM sales AS m JOIN store AS s ON s.id = m.store_id ORDER BY s.name, m.month;
-- change from the previous month
SELECT store_id, month, revenue - lag(revenue) OVER (PARTITION BY store_id ORDER BY month) AS delta
  FROM sales ORDER BY store_id, month;
-- rank stores within each month
SELECT month, store_id, rank() OVER (PARTITION BY month ORDER BY revenue DESC) AS r
  FROM sales WHERE revenue IS NOT NULL ORDER BY month, r, store_id;
-- each store's total and its rank
SELECT s.name, sum(m.revenue) AS tot, rank() OVER (ORDER BY sum(m.revenue) DESC) AS r
  FROM store AS s JOIN sales AS m ON m.store_id = s.id GROUP BY s.name ORDER BY r, s.name;
-- share of the city's revenue
SELECT s.city, s.name, sum(m.revenue) * 100 / sum(sum(m.revenue)) OVER (PARTITION BY s.city) AS pct
  FROM store AS s JOIN sales AS m ON m.store_id = s.id GROUP BY s.city, s.name ORDER BY s.city, s.name;
-- a missing month is filled in and the report changes
UPDATE sales SET revenue = 65 WHERE store_id = 3 AND month = 2;
SELECT month, sum(revenue), sum(sum(revenue)) OVER (ORDER BY month) FROM sales GROUP BY month ORDER BY month;
SELECT store_id, month, avg(revenue) OVER (PARTITION BY store_id ORDER BY month ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
  FROM sales WHERE store_id = 3 ORDER BY month;
-- best month per store
SELECT store_id, month, revenue FROM
  (SELECT store_id, month, revenue, row_number() OVER (PARTITION BY store_id ORDER BY revenue DESC, month) AS rn FROM sales)
  WHERE rn = 1 ORDER BY store_id;
CREATE VIEW monthly AS SELECT month, sum(revenue) AS total FROM sales GROUP BY month;
SELECT month, total, total - lag(total, 1, 0) OVER (ORDER BY month) FROM monthly ORDER BY month;
DELETE FROM sales WHERE month = 1;
SELECT month, total, rank() OVER (ORDER BY total) FROM monthly ORDER BY month;
SELECT store_id, first_value(month) OVER (PARTITION BY store_id ORDER BY revenue) FROM sales WHERE month = 3 ORDER BY store_id;

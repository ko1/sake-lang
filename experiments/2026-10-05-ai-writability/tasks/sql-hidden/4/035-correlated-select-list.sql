-- Several correlated scalar subqueries per row, also used for sorting.
CREATE TABLE shops (sid INTEGER, town TEXT);
CREATE TABLE sales (sid INTEGER, month INTEGER, amount INTEGER);
INSERT INTO shops VALUES (1, 'Ayr'), (2, 'Bath'), (3, 'Cork'), (4, 'Derby');
INSERT INTO sales VALUES (1, 1, 100), (1, 2, 150), (2, 1, 300), (3, 1, 50), (3, 2, 60), (3, 3, 70);
SELECT town, (SELECT count(*) FROM sales WHERE sales.sid = shops.sid) AS months,
  (SELECT max(amount) FROM sales WHERE sales.sid = shops.sid) AS best FROM shops ORDER BY town;
SELECT town FROM shops ORDER BY (SELECT total(amount) FROM sales s WHERE s.sid = shops.sid) DESC;
SELECT town, (SELECT amount FROM sales s WHERE s.sid = shops.sid ORDER BY month DESC LIMIT 1) AS last_amount
  FROM shops WHERE (SELECT count(*) FROM sales s WHERE s.sid = shops.sid) > 1 ORDER BY town;
SELECT month, (SELECT town FROM shops WHERE shops.sid = s.sid) FROM sales s WHERE amount >= 100 ORDER BY month, amount;

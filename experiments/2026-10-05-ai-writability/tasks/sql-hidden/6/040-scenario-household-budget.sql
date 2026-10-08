-- scenario: a household budget with categories, monthly totals, trends and outliers
CREATE TABLE cat (name TEXT PRIMARY KEY, kind TEXT NOT NULL);
CREATE TABLE spend (id INTEGER PRIMARY KEY, month INTEGER NOT NULL, cat TEXT NOT NULL, amount REAL NOT NULL);
INSERT INTO cat VALUES ('rent','fixed'),('power','fixed'),('food','variable'),('fun','variable');
INSERT INTO spend (month, cat, amount) VALUES (1,'rent',900),(1,'power',60.5),(1,'food',310.25),(1,'fun',80),
  (2,'rent',900),(2,'power',72),(2,'food',280.75),(2,'fun',150),(3,'rent',950),(3,'power',55.5),(3,'food',330),(3,'fun',40.25);
INSERT INTO spend (month, cat, amount) VALUES (3, 'fun', 'cinema');
SELECT month, sum(amount), sum(sum(amount)) OVER (ORDER BY month) AS ytd FROM spend GROUP BY month ORDER BY month;
SELECT month, cat, amount - lag(amount) OVER (PARTITION BY cat ORDER BY month) AS delta FROM spend ORDER BY cat, month;
SELECT c.kind, s.month, sum(s.amount), rank() OVER (PARTITION BY c.kind ORDER BY sum(s.amount) DESC) FROM spend AS s JOIN cat AS c ON c.name = s.cat
  GROUP BY c.kind, s.month ORDER BY c.kind, s.month;
-- the biggest category each month
SELECT month, cat FROM (SELECT month, cat, rank() OVER (PARTITION BY month ORDER BY amount DESC) AS r FROM spend) WHERE r = 1 ORDER BY month;
SELECT month, cat FROM (SELECT month, cat, rank() OVER (PARTITION BY month ORDER BY amount DESC) AS r FROM spend) WHERE r = 2 ORDER BY month;
-- months where a category was above its own average
SELECT cat, month, amount FROM (SELECT cat, month, amount, avg(amount) OVER (PARTITION BY cat) AS a FROM spend) WHERE amount > a ORDER BY cat, month;
SELECT cat, round(avg(amount), 2), max(amount) - min(amount), dense_rank() OVER (ORDER BY max(amount) - min(amount) DESC) FROM spend GROUP BY cat ORDER BY cat;
-- a two-month moving average for food
SELECT month, avg(amount) OVER (ORDER BY month ROWS 1 PRECEDING) FROM spend WHERE cat = 'food' ORDER BY month;
-- add month 4 inside a transaction, then keep it
BEGIN;
INSERT INTO spend (month, cat, amount) SELECT 4, cat, amount FROM spend WHERE month = 3 AND cat IN ('rent', 'power');
INSERT INTO spend (month, cat, amount) VALUES (4, 'food', 300), (4, 'fun', 120);
COMMIT;
SELECT month, sum(amount), sum(amount) - lag(sum(amount)) OVER (ORDER BY month) FROM spend GROUP BY month ORDER BY month;
SELECT cat, month, ntile(2) OVER (PARTITION BY cat ORDER BY month) AS half FROM spend WHERE cat = 'fun' ORDER BY month;
SELECT cat, month, amount, max(amount) OVER (PARTITION BY cat ORDER BY month RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING) FROM spend WHERE cat = 'fun' ORDER BY month;
SELECT cat, month, cume_dist() OVER (PARTITION BY cat ORDER BY amount) FROM spend WHERE cat = 'rent' ORDER BY month;
CREATE VIEW share AS SELECT month, cat, round(100 * amount / sum(amount) OVER (PARTITION BY month), 1) AS pct FROM spend;
SELECT month, cat, pct FROM share WHERE cat = 'rent' ORDER BY month;
SELECT month, cat, pct FROM share WHERE month = 4 ORDER BY pct DESC, cat;
SELECT DISTINCT month, first_value(cat) OVER (PARTITION BY month ORDER BY amount) FROM spend ORDER BY month;
SELECT cat, count(*), group_concat(month, '') OVER (ORDER BY cat, month) FROM spend WHERE amount > 100 GROUP BY cat, month ORDER BY cat, month;

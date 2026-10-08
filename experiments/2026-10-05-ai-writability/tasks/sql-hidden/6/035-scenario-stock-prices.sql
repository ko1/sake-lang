-- scenario: daily closing prices, returns, moving averages and drawdowns
CREATE TABLE quote (sym TEXT NOT NULL, d INTEGER NOT NULL, close INTEGER NOT NULL, PRIMARY KEY (sym, d));
INSERT INTO quote VALUES ('abc',1,100),('abc',2,104),('abc',3,101),('abc',4,110),('abc',5,108),('abc',8,115),
  ('xyz',1,50),('xyz',2,48),('xyz',3,47),('xyz',4,52),('xyz',5,52),('xyz',8,49);
INSERT INTO quote VALUES ('abc',3,99);
SELECT sym, d, close - lag(close) OVER (PARTITION BY sym ORDER BY d) AS chg FROM quote ORDER BY sym, d;
SELECT sym, d, round(100.0 * (close - lag(close) OVER (PARTITION BY sym ORDER BY d)) / lag(close) OVER (PARTITION BY sym ORDER BY d), 2) FROM quote ORDER BY sym, d;
-- 3-row moving average and a 3-day calendar window
SELECT sym, d, round(avg(close) OVER (PARTITION BY sym ORDER BY d ROWS 2 PRECEDING), 2), count(*) OVER (PARTITION BY sym ORDER BY d RANGE 2 PRECEDING) FROM quote ORDER BY sym, d;
-- peak so far and drawdown from it
SELECT sym, d, max(close) OVER (PARTITION BY sym ORDER BY d) AS peak, close - max(close) OVER (PARTITION BY sym ORDER BY d) AS dd FROM quote ORDER BY sym, d;
SELECT sym, min(dd) FROM (SELECT sym, close - max(close) OVER (PARTITION BY sym ORDER BY d) AS dd FROM quote) GROUP BY sym ORDER BY sym;
-- best and worst days
SELECT sym, d, close FROM (SELECT sym, d, close, rank() OVER (PARTITION BY sym ORDER BY close DESC) AS r FROM quote) WHERE r = 1 ORDER BY sym, d;
SELECT sym, d, close, dense_rank() OVER (PARTITION BY sym ORDER BY close) FROM quote WHERE sym = 'xyz' ORDER BY d;
-- up days in a row
CREATE VIEW moves AS SELECT sym, d, CASE WHEN close > lag(close) OVER (PARTITION BY sym ORDER BY d) THEN 'up' ELSE 'down' END AS dir FROM quote;
SELECT sym, group_concat(dir, ' ' ORDER BY d) FROM moves GROUP BY sym ORDER BY sym;
SELECT sym, d, dir, lead(dir) OVER (PARTITION BY sym ORDER BY d) FROM moves WHERE d > 1 ORDER BY sym, d;
SELECT sym, count(*) FROM moves WHERE dir = 'up' GROUP BY sym ORDER BY sym;
-- a correction to a price
UPDATE quote SET close = 112 WHERE sym = 'abc' AND d = 5;
SELECT d, close, max(close) OVER (ORDER BY d ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) FROM quote WHERE sym = 'abc' ORDER BY d;
SELECT d, sum(close), sum(close) - lag(sum(close), 1, 0) OVER (ORDER BY d) FROM quote GROUP BY d ORDER BY d;
SELECT sym, d, ntile(3) OVER (PARTITION BY sym ORDER BY d) FROM quote ORDER BY sym, d;
SELECT sym, d, first_value(close) OVER (PARTITION BY sym ORDER BY d RANGE BETWEEN 3 PRECEDING AND CURRENT ROW) FROM quote ORDER BY sym, d;
SELECT sym, d, last_value(close) OVER (PARTITION BY sym ORDER BY d RANGE BETWEEN CURRENT ROW AND 3 FOLLOWING) FROM quote ORDER BY sym, d;
SELECT sym, percent_rank() OVER (ORDER BY max(close) - min(close)) FROM quote GROUP BY sym ORDER BY sym;

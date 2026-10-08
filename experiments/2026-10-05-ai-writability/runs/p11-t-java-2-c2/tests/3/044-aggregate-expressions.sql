CREATE TABLE lines (ord INTEGER, qty INTEGER, unit REAL);
INSERT INTO lines VALUES (1, 2, 1.5), (1, 1, 4.0), (2, 10, 0.25), (3, 3, 2.0);
SELECT ord, sum(qty * unit) AS amount FROM lines GROUP BY ord ORDER BY ord;
SELECT count(*) * 100, sum(qty) + 1, max(unit) * 2 FROM lines;
SELECT round(avg(qty * unit), 2) FROM lines;
SELECT ord, count(*) > 1 AS multi FROM lines GROUP BY ord ORDER BY ord;
SELECT 'n=' || count(*) FROM lines;

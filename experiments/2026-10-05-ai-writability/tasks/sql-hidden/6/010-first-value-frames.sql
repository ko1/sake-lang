CREATE TABLE price (d INTEGER, sym TEXT, px INTEGER);
INSERT INTO price VALUES (1,'aa',10),(2,'aa',12),(3,'aa',9),(4,'aa',15),(1,'bb',100),(2,'bb',98),(3,'bb',NULL);
SELECT sym, d, first_value(px) OVER (PARTITION BY sym ORDER BY d) FROM price ORDER BY sym, d;
SELECT sym, d, first_value(px) OVER (PARTITION BY sym ORDER BY d ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) FROM price ORDER BY sym, d;
SELECT sym, d, first_value(px) OVER (PARTITION BY sym ORDER BY d DESC) FROM price ORDER BY sym, d;
SELECT sym, d, first_value(d) OVER (PARTITION BY sym ORDER BY px DESC NULLS LAST) FROM price ORDER BY sym, d;
SELECT sym, d, first_value(px) OVER (PARTITION BY sym ORDER BY d ROWS BETWEEN 2 FOLLOWING AND UNBOUNDED FOLLOWING) FROM price ORDER BY sym, d;

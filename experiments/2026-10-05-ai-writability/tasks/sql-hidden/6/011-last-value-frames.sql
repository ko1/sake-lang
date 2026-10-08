CREATE TABLE price (d INTEGER, sym TEXT, px INTEGER);
INSERT INTO price VALUES (1,'aa',10),(2,'aa',12),(2,'bb',12),(3,'aa',9),(4,'aa',15),(1,'bb',100),(3,'bb',7);
SELECT sym, d, last_value(px) OVER (PARTITION BY sym ORDER BY d) FROM price ORDER BY sym, d;
SELECT sym, d, last_value(d) OVER (ORDER BY px RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) FROM price WHERE sym = 'aa' ORDER BY d;
SELECT sym, d, last_value(px) OVER (PARTITION BY sym ORDER BY d ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) FROM price ORDER BY sym, d;
SELECT sym, d, last_value(px) OVER (PARTITION BY sym ORDER BY d ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) FROM price ORDER BY sym, d;
SELECT d, last_value(sym) OVER (ORDER BY d, sym DESC) FROM price ORDER BY d, sym;

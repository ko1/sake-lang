CREATE TABLE sales (region TEXT, units INTEGER);
SELECT total(units), sum(units) FROM sales;
INSERT INTO sales VALUES ('north', 4), ('south', NULL), ('north', 6);
SELECT total(units), typeof(total(units)) FROM sales;
SELECT total(units) FROM sales WHERE region = 'south';
SELECT sum(units) FROM sales WHERE region = 'south';
SELECT region, total(units) FROM sales GROUP BY region ORDER BY region;

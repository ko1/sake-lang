CREATE TABLE cars (make TEXT, price INTEGER);
INSERT INTO cars VALUES ('vw', 20), ('vw', 22), ('fiat', 15), ('audi', 40), ('fiat', 9), ('fiat', 11);
SELECT make, count(*) AS price FROM cars GROUP BY make ORDER BY price;
SELECT make, sum(price) AS make FROM cars GROUP BY make ORDER BY make DESC;
SELECT make AS m, max(price) FROM cars GROUP BY m ORDER BY 2;
SELECT make, avg(price) FROM cars GROUP BY make ORDER BY 3;

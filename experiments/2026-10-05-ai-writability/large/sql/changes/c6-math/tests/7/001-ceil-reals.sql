-- ceil rounds a REAL up to a whole number and keeps it REAL
SELECT ceil(1.2), ceil(-1.2), ceil(3.0), ceil(0.001), ceil(-0.999);
SELECT ceiling(2.1), CEILING(-7.5), Ceil(100.25);
SELECT typeof(ceil(1.5)), typeof(ceiling(-2.0));
CREATE TABLE price (item TEXT, cost REAL);
INSERT INTO price VALUES ('pen', 1.25), ('book', 12.0), ('lamp', 30.01), ('cup', 4.5);
SELECT item, cost, ceil(cost) FROM price ORDER BY item;
SELECT item FROM price WHERE ceil(cost) = cost ORDER BY item;

CREATE TABLE prices (shop TEXT, item TEXT, cost REAL);
INSERT INTO prices VALUES ('s1', 'tea', 2.5), ('s2', 'tea', 1.75), ('s3', 'tea', 3.0), ('s1', 'jam', 4.0), ('s2', 'jam', 4.5);
SELECT item, min(cost), shop FROM prices GROUP BY item ORDER BY item;
SELECT shop, min(cost) FROM prices WHERE item = 'tea';
SELECT upper(shop) AS who, min(cost) AS best FROM prices GROUP BY item ORDER BY best;

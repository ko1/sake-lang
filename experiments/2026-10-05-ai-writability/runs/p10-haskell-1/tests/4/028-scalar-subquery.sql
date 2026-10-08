-- A scalar subquery is its first row's first column, or NULL when there are no rows.
CREATE TABLE prices (item TEXT, price REAL);
INSERT INTO prices VALUES ('tea', 2.5), ('cake', 4.0), ('jam', 3.25);
SELECT (SELECT max(price) FROM prices);
SELECT (SELECT item FROM prices ORDER BY price LIMIT 1);
SELECT (SELECT item FROM prices ORDER BY price DESC);
SELECT (SELECT item FROM prices WHERE price > 10);
SELECT typeof((SELECT price FROM prices WHERE item = 'none'));
SELECT item, price - (SELECT avg(price) FROM prices) AS diff FROM prices ORDER BY diff;
SELECT item FROM prices WHERE price > (SELECT price FROM prices WHERE item = 'tea') ORDER BY item;
SELECT (SELECT count(*) FROM prices) * 10, (SELECT 'k') || (SELECT 7);

-- a cte hides a table everywhere in its statement, including subqueries
CREATE TABLE price (item TEXT, p INTEGER);
INSERT INTO price VALUES ('tea', 3), ('cake', 5);
WITH price AS (SELECT 'tea' AS item, 100 AS p) SELECT item, (SELECT max(p) FROM price) FROM price;
SELECT item FROM price WHERE p = (WITH price AS (SELECT 5 AS p) SELECT p FROM price);
WITH cheap AS (SELECT item FROM price WHERE p < 4) SELECT item FROM price WHERE item NOT IN (SELECT item FROM cheap);
SELECT max(p) FROM price;

-- a cte hides a table of the same name, only inside its statement
CREATE TABLE items (name TEXT, qty INTEGER);
INSERT INTO items VALUES ('nut', 4), ('bolt', 0);
WITH items AS (SELECT 'gear' AS name, 9 AS qty) SELECT name, qty FROM items;
SELECT name, qty FROM items ORDER BY name;
SELECT (WITH items AS (SELECT 1 AS name) SELECT count(*) FROM items), count(*) FROM items;
SELECT count(*) FROM items;

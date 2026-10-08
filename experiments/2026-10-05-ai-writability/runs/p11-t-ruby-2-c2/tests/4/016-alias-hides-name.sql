-- A table that has an alias is known only by its alias.
CREATE TABLE fruit (name TEXT, kg REAL);
INSERT INTO fruit VALUES ('apple', 1.5), ('fig', 0.25);
SELECT f.name FROM fruit f ORDER BY 1;
SELECT fruit.name FROM fruit f;
SELECT fruit.* FROM fruit AS f;
SELECT name FROM fruit AS f WHERE fruit.kg > 1;
SELECT f.name FROM fruit AS f ORDER BY fruit.kg;
SELECT fruit.kg FROM fruit ORDER BY fruit.name;

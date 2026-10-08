-- row_number() numbers the rows in the window's order, independent of the final ORDER BY
CREATE TABLE fruit (name TEXT, price INTEGER);
INSERT INTO fruit VALUES ('apple', 30), ('kiwi', 12), ('pear', 25), ('fig', 40), ('lime', 8);
SELECT name, row_number() OVER (ORDER BY price) FROM fruit ORDER BY name;
SELECT name, row_number() OVER (ORDER BY price DESC) AS rn FROM fruit ORDER BY rn;
SELECT name, row_number() OVER (ORDER BY name DESC) FROM fruit ORDER BY price;
SELECT row_number() OVER (ORDER BY price) * 10, name FROM fruit WHERE price > 10 ORDER BY 1;

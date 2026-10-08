-- the trailing ORDER BY applies to the whole result; integer terms name columns
CREATE TABLE p (name TEXT, price INTEGER);
CREATE TABLE q (name TEXT, price INTEGER);
INSERT INTO p VALUES ('apple', 30), ('pear', 10);
INSERT INTO q VALUES ('fig', 20), ('kiwi', 30);
SELECT name, price FROM p UNION ALL SELECT name, price FROM q ORDER BY 2 DESC, 1;
SELECT name, price FROM p UNION SELECT name, price FROM q ORDER BY 2, 1 DESC;
SELECT price FROM p UNION SELECT price FROM q ORDER BY 1 DESC;
SELECT name FROM p UNION SELECT name FROM q ORDER BY 2;
SELECT name, price FROM p UNION SELECT name, price FROM q ORDER BY 0;

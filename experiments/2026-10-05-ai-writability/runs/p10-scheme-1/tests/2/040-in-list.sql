CREATE TABLE fruit (name TEXT, color TEXT, kg REAL);
INSERT INTO fruit VALUES ('apple', 'red', 1.5), ('banana', 'yellow', 2.0), ('cherry', 'red', 0.5), ('lime', 'green', 1.0);
SELECT name FROM fruit WHERE color IN ('red', 'green') ORDER BY name;
SELECT name FROM fruit WHERE color NOT IN ('red') ORDER BY name;
SELECT name FROM fruit WHERE kg IN (1, 2) ORDER BY name;
SELECT name, name IN ('lime', 'kiwi') FROM fruit ORDER BY name;
SELECT 3 IN (1, 2, 3), 4 IN (1 + 3), 'a' IN ('A'), 1 IN (1.0);

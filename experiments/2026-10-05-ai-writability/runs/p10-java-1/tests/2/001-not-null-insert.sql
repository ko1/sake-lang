-- NOT NULL rejects a NULL, whether written or left out
CREATE TABLE people (name TEXT NOT NULL, age INTEGER);
INSERT INTO people VALUES ('Ann', 30);
INSERT INTO people VALUES (NULL, 40);
INSERT INTO people (age) VALUES (50);
INSERT INTO people (name) VALUES ('Bob');
INSERT INTO people VALUES ('', NULL);
SELECT name, age FROM people ORDER BY name;
SELECT name || '!' FROM people WHERE age IS NULL ORDER BY name;

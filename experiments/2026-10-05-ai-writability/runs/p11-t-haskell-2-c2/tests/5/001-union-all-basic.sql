-- UNION ALL keeps every row of both sides, duplicates included
CREATE TABLE cats (name TEXT, age INTEGER);
CREATE TABLE dogs (name TEXT, age INTEGER);
INSERT INTO cats VALUES ('Tom', 3), ('Kitty', 5);
INSERT INTO dogs VALUES ('Rex', 3), ('Tom', 3);
SELECT name, age FROM cats UNION ALL SELECT name, age FROM dogs ORDER BY name, age;
SELECT age FROM cats UNION ALL SELECT age FROM dogs ORDER BY 1;
SELECT count(*) FROM (SELECT name FROM cats UNION ALL SELECT name FROM dogs);

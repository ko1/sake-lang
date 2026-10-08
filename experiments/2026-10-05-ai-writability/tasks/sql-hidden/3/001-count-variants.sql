CREATE TABLE people (id INTEGER PRIMARY KEY, nick TEXT, age INTEGER);
INSERT INTO people (nick, age) VALUES ('zed', 30), (NULL, 41), ('yo', NULL), ('xi', 19), (NULL, NULL);
SELECT count(*), count(nick), count(age), count(nick || age) FROM people;
SELECT count(CASE WHEN age > 20 THEN nick END) FROM people;
SELECT count(nick LIKE 'x%'), count(*) - count(nick) FROM people;
SELECT count(age) FROM people WHERE id > 100;
SELECT Count(*) * 2 FROM people WHERE age BETWEEN 18 AND 35;
SELECT count(CAST(age AS TEXT)), count('') FROM people;

CREATE TABLE hh (name TEXT, score INTEGER);
INSERT INTO hh VALUES ('a', 5), ('b', 7);
SELECT name FROM hh HAVING score > 5 ORDER BY name;
SELECT name, score FROM hh WHERE score < 10 HAVING name = 'a' LIMIT 1;
SELECT DISTINCT score FROM hh HAVING 1 = 1;
SELECT min(score, 6) AS m FROM hh HAVING m > 5;
SELECT name FROM hh GROUP BY name HAVING score > 5 ORDER BY name;

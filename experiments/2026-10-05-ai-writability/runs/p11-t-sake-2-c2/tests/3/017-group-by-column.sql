CREATE TABLE pets (owner TEXT, kind TEXT, age INTEGER);
INSERT INTO pets VALUES ('ann', 'cat', 3), ('bob', 'dog', 5), ('ann', 'dog', 1), ('cy', 'cat', 7), ('bob', 'dog', 2);
SELECT owner, count(*) FROM pets GROUP BY owner ORDER BY owner;
SELECT kind, sum(age), max(age) FROM pets GROUP BY kind ORDER BY kind;
SELECT kind FROM pets GROUP BY kind ORDER BY kind DESC;
SELECT count(*) FROM pets GROUP BY owner ORDER BY 1;
SELECT owner, avg(age) FROM pets WHERE kind = 'dog' GROUP BY owner ORDER BY owner;
